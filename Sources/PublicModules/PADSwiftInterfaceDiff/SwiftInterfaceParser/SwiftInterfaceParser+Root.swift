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

        var adjustedElements: [any SwiftInterfaceElement] = nonExtensions

        extensions.forEach { extensionElement in

            // We want to merge all extensions that don't have a where clause into the extended type
            guard extensionElement.genericWhereClauseDescription == nil else {
                adjustedElements.append(extensionElement)
                return
            }

            if merge(extensionElement: extensionElement, with: extendableElements, prefix: moduleName) {
                return // We found the matching extended element
            }

            // We could not find the extended type so we add the extension to the list
            adjustedElements.append(extensionElement)
        }

        return adjustedElements
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
        for extendedElement in extendableElements {
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
