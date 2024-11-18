//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

extension SwiftInterfaceParser {

    /// The root element returned as the result of parsing the interface
    class Root: SwiftInterfaceElement {

        static var declType: SwiftInterfaceElementDeclType { .root }
        
        var parent: (any SwiftInterfaceElement)?

        var diffableSignature: String { "" }

        var consolidatableName: String { "" }

        /// Produces the complete recursive description of the interface
        var description: String {
            var description = ""
            children.forEach { child in
                description.append(child.recursiveDescription())
                description.append("\n")
            }
            return description
        }

        var pathComponentName: String { moduleName }

        private let moduleName: String
        private(set) var children: [any SwiftInterfaceElement]

        init(moduleName: String, elements: [any SwiftInterfaceElement]) {
            self.moduleName = moduleName
            self.children = elements

            self.children = Self.mergeExtensions(for: self.children, moduleName: moduleName)
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

        let extensions = elements.compactMap { $0 as? SwiftInterfaceExtension }
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

        // Finding the first extendable element that has the same prefix as the extension
        guard let extendedElement = extendableElements.first(where: { extensionElement.extendedType.hasPrefix("\(prefix).\($0.typeName)") }) else {
            return false
        }

        let extendedElementPrefix = "\(prefix).\(extendedElement.typeName)"

        // We found the extended type
        if extendedElementPrefix == extensionElement.extendedType {
            extendedElement.inheritance = (extendedElement.inheritance ?? []) + (extensionElement.inheritance ?? [])
            extendedElement.children += extensionElement.children
            return true
        }

        // We're looking for the extended type inside of the children
        let extendableChildren = extendedElement.children.compactMap { $0 as? SwiftInterfaceExtendableElement }
        return merge(extensionElement: extensionElement, with: extendableChildren, prefix: extendedElementPrefix)
    }
}
