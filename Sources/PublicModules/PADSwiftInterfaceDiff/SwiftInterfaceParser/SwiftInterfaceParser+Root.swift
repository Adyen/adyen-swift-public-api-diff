//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

extension SwiftInterfaceParser {

    /// The root element returned as the result of parsing the interface
    class Root: SwiftInterfaceElement {

        var parent: (any SwiftInterfaceElement)?

        var diffableSignature: String { "" }

        var consolidatableName: String { "" }

        /// Produces the complete recursive description of the interface
        func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
            var descriptionElements: [String] = []
            children.forEach { child in
                descriptionElements.append(child.recursiveDescription(incl: tokens))
            }
            return descriptionElements.joined(separator: "\n")
        }

        var pathComponentName: String { moduleName }

        private let moduleName: String
        private(set) var children: [any SwiftInterfaceElement]

        init(moduleName: String, elements: [any SwiftInterfaceElement]) {
            self.moduleName = moduleName

            self.children = Self.mergeExtensions(for: elements, moduleName: moduleName)
            self.children.forEach { $0.setupParentRelationships(parent: self) }
        }

        func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
            []
        }
    }
}

// MARK: - Convenience methods

private extension SwiftInterfaceParser.Root {

    /// Attempting to merge extensions into their extended type to allow for better diffing
    ///
    /// Independent extensions (without a where clause) are very hard to diff as the only information we have
    /// is the ``SwiftInterfaceExtension.extendedType`` and there might be a lot of changes inside of the extensions between versions
    ///
    /// Example:
    /// ```
    /// struct S {
    ///    var a: String
    /// }
    ///
    /// extension S: SomeProtocol {
    ///     var b: Int { 1 }
    /// }
    /// ```
    ///
    /// ... Is turned into ...
    /// ```
    /// struct S: SomeProtocol {
    ///    var a: String
    ///    var b: Int { 1 }
    /// }
    /// ```
    static func mergeExtensions(for elements: [any SwiftInterfaceElement], moduleName: String) -> [any SwiftInterfaceElement] {

        // Shallower extensions first (stable within a depth): `extension M.A { struct B }` must be merged
        // before `extension M.A.B` can find `B`, regardless of where either appears in the file.
        let extensions = elements
            .compactMap { $0 as? SwiftInterfaceExtension }
            .enumerated()
            .sorted { lhs, rhs in
                let lhsDepth = lhs.element.extendedType.split(separator: ".").count
                let rhsDepth = rhs.element.extendedType.split(separator: ".").count
                return lhsDepth == rhsDepth ? lhs.offset < rhs.offset : lhsDepth < rhsDepth
            }
            .map(\.element)
        let extendableElements = elements.compactMap { $0 as? SwiftInterfaceExtendableElement }
        let nonExtensions = elements.filter { !($0 is SwiftInterfaceExtension) }

        var standaloneExtensions = [SwiftInterfaceExtension]()

        extensions.forEach { extensionElement in

            // We want to merge all extensions that don't have a where clause into the extended type
            guard extensionElement.genericWhereClauseDescription == nil else {
                standaloneExtensions.append(extensionElement)
                return
            }

            if merge(extensionElement: extensionElement, with: extendableElements, prefix: moduleName) {
                return // We found the matching extended element
            }

            // We could not find the extended type (e.g. it's declared in another module)
            standaloneExtensions.append(extensionElement)
        }

        return nonExtensions + combine(standaloneExtensions: standaloneExtensions)
    }

    /// Combines the extensions that can't be merged into their extended type (e.g. extensions of types
    /// of other modules or extensions with a where clause) into one extension per extended type,
    /// generic where clause and (non-availability) attributes and modifiers
    ///
    /// Interfaces split and merge extension blocks between versions (e.g. one block per availability),
    /// so comparing them block by block reports members that only moved to another block as changed.
    /// As with extensions merged into their type, an extension's `@available` attributes are applied
    /// to its members and conformances (see ``AvailabilityInheritance``).
    ///
    /// Example:
    /// ```
    /// @available(iOS 17.0, *)
    /// extension Other.View: Other.Hoverable {
    ///     func hover()
    /// }
    ///
    /// extension Other.View {
    ///     func tap()
    /// }
    /// ```
    ///
    /// ... Is turned into ...
    /// ```
    /// extension Other.View {
    ///     @available(iOS 17.0, *)
    ///     func hover()
    ///     func tap()
    /// }
    ///
    /// @available(iOS 17.0, *)
    /// extension Other.View: Other.Hoverable
    /// ```
    static func combine(standaloneExtensions: [SwiftInterfaceExtension]) -> [SwiftInterfaceExtension] {

        struct GroupKey: Hashable {
            let extendedType: String
            let genericWhereClause: String?
            let attributes: [String]
            let modifiers: [String]
        }

        func headerAttributes(of extensionElement: SwiftInterfaceExtension) -> [String] {
            extensionElement.attributes.filter { !$0.hasPrefix("@available(") }
        }

        var groupKeys = [GroupKey]()
        var groups = [GroupKey: [SwiftInterfaceExtension]]()
        for extensionElement in standaloneExtensions {
            let key = GroupKey(
                extendedType: extensionElement.extendedType,
                genericWhereClause: extensionElement.genericWhereClauseDescription,
                attributes: headerAttributes(of: extensionElement).sorted(),
                modifiers: extensionElement.modifiers.sorted()
            )
            if groups[key] == nil { groupKeys.append(key) }
            groups[key, default: []].append(extensionElement)
        }

        return groupKeys.compactMap { key in
            guard let extensionElements = groups[key], let first = extensionElements.first else { return nil }
            let attributes = headerAttributes(of: first)

            var inheritance = [String]()
            var children = [any SwiftInterfaceElement]()
            for extensionElement in extensionElements {
                for conformance in extensionElement.inheritance ?? [] {
                    let conformance = AvailabilityInheritance.conformance(
                        conformance,
                        declaredWith: extensionElement.attributes,
                        on: attributes
                    )
                    if !inheritance.contains(conformance) { inheritance.append(conformance) }
                }
                for child in extensionElement.children {
                    if let attributedChild = child as? SwiftInterfaceAttributedElement {
                        attributedChild.attributes = AvailabilityInheritance.attributes(
                            attributedChild.attributes,
                            inheriting: extensionElement.attributes
                        )
                    }
                    children.append(child)
                }
            }

            return SwiftInterfaceExtension(
                attributes: attributes,
                modifiers: first.modifiers,
                extendedType: key.extendedType,
                inheritance: inheritance.isEmpty ? nil : inheritance,
                genericWhereClauseDescription: key.genericWhereClause,
                children: children
            )
        }
    }

    /// Attempting to recursively merge an extension element with potential matches of extendable elements
    /// The prefix provides the parent path as the types don't include it but the `extension.extendedType` does
    ///
    /// Example:
    /// ```
    /// struct S {
    ///    enum E {
    ///       class C {}
    ///    }
    /// }
    ///
    /// extension S.E.C: SomeProtocol {
    ///     var b: Int { 1 }
    /// }
    /// ```
    ///
    /// ... Is turned into ...
    /// ```
    /// struct S {
    ///    enum E {
    ///       class C: SomeProtocol {
    ///          var b: Int { 1 }
    ///       }
    ///    }
    /// }
    /// ```
    static func merge(
        extensionElement: SwiftInterfaceExtension,
        with extendableElements: [any SwiftInterfaceExtendableElement],
        prefix: String
    ) -> Bool {

        // Matching on whole path components so that e.g. `extension M.TabContent`
        // is never routed into `struct M.Tab` (a plain `hasPrefix` made the merge
        // depend on declaration order). Every candidate is tried, not just the first.
        let extendedType = extensionElement.extendedType
        for extendedElement in preferringSameConditions(extendableElements, as: extensionElement) {
            let extendedElementPrefix = "\(prefix).\(extendedElement.typeName)"
            guard extendedType == extendedElementPrefix || extendedType.hasPrefix("\(extendedElementPrefix).") else {
                continue
            }
            if merge(extensionElement: extensionElement, into: extendedElement, prefix: extendedElementPrefix) {
                return true
            }
        }
        return false
    }

    /// Variants of a type declared in different `#if` clauses (see ``ConditionalCompilation``):
    /// an extension is merged into the variant declared under (a subset of) the extension's conditions,
    /// preferring the one sharing most conditions, otherwise into the first variant.
    static func preferringSameConditions(
        _ extendableElements: [any SwiftInterfaceExtendableElement],
        as extensionElement: SwiftInterfaceExtension
    ) -> [any SwiftInterfaceExtendableElement] {
        let extensionConditions = Set(extensionElement.conditions)
        guard extendableElements.contains(where: { !$0.conditions.isEmpty }) else { return extendableElements }
        return extendableElements.enumerated().sorted { lhs, rhs in
            func rank(_ element: any SwiftInterfaceExtendableElement, _ offset: Int) -> [Int] {
                let conditions = Set(element.conditions)
                return [
                    conditions.isSubset(of: extensionConditions) ? 0 : 1,
                    -conditions.intersection(extensionConditions).count,
                    offset
                ]
            }
            return rank(lhs.element, lhs.offset).lexicographicallyPrecedes(rank(rhs.element, rhs.offset))
        }.map(\.element)
    }

    static func merge(
        extensionElement: SwiftInterfaceExtension,
        into extendedElement: any SwiftInterfaceExtendableElement,
        prefix extendedElementPrefix: String
    ) -> Bool {

        // We found the extended type
        if extendedElementPrefix == extensionElement.extendedType {
            // Conformances declared in an extension with its own availability keep it,
            // so e.g. a `Hashable` conformance arriving on a new platform stays visible.
            let conformances = (extensionElement.inheritance ?? []).map {
                AvailabilityInheritance.conformance(
                    $0,
                    declaredWith: extensionElement.attributes,
                    on: (extendedElement as? SwiftInterfaceAttributedElement)?.attributes ?? []
                )
            }
            extendedElement.inheritance = (extendedElement.inheritance ?? []) + conformances

            extensionElement.children.forEach { child in
                // Filtering out default implementations with custom modifiers (public/package/...)
                if extendedElement.children.contains(where: {
                    $0.description(excl: [.modifiers]) == child.description(excl: [.modifiers])
                }) {
                    return
                }
                // The extension's `@available` applies to its members; keep it on them
                // so availability changes of the extension stay visible after merging.
                if let attributedChild = child as? SwiftInterfaceAttributedElement {
                    attributedChild.attributes = AvailabilityInheritance.attributes(
                        attributedChild.attributes,
                        inheriting: extensionElement.attributes
                    )
                    // Same for the conditions of `#if` clauses the extension is declared in
                    let typeConditions = Set(extendedElement.conditions)
                    attributedChild.attributes = ConditionalCompilation.attributes(
                        attributedChild.attributes,
                        adding: extensionElement.conditions.filter { !typeConditions.contains($0) }
                    )
                }
                extendedElement.children += [child]
            }
            
            return true
        }

        // We're looking for the extended type inside of the children
        let extendableChildren = extendedElement.children.compactMap { $0 as? SwiftInterfaceExtendableElement }
        return merge(extensionElement: extensionElement, with: extendableChildren, prefix: extendedElementPrefix)
    }
}
