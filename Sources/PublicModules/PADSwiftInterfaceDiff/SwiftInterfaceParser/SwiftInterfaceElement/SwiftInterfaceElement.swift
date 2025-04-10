//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

protocol SwiftInterfaceExtendableElement: SwiftInterfaceElement {

    /// Name of the type
    ///
    /// Is used to match an extension's `extendedType` to the element it extends
    var typeName: String { get }

    /// Types/Protocols the element inherits from
    var inheritance: [String]? { get set }

    var children: [any SwiftInterfaceElement] { get set }
}

enum SwiftInterfaceElementDescriptionToken: CaseIterable {
    case attributes
    case modifiers
    // Add more tokens when needed
}

protocol SwiftInterfaceElement: CustomStringConvertible, AnyObject {
    
    /// The name of the element used to construct the parent path for its children
    var pathComponentName: String { get }

    /// The full description of the element (without children)
    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String

    /// The cildren of the element (e.g. properties/functions of a struct/class/...)
    var children: [any SwiftInterfaceElement] { get }

    /// A reduced signature of the element to be used to find 2 versions of the same element in a diff
    /// by deliberately omitting specifics like types and other decorators.
    ///
    /// e.g. `func foo(bar: Int = 0, baz: String)` would have a diffable signature of `foo(bar:baz)`
    var diffableSignature: String { get }

    /// A very reduced signature that allows consolidating changes
    ///
    /// e.g. `func foo(bar: Int = 0, baz: String)` would have a consolidatable name of `foo`
    var consolidatableName: String { get }

    /// The parent of the element (setup by using ``setupParentRelationships(parent:)``
    var parent: (any SwiftInterfaceElement)? { get set }

    /// Produces a list of differences between one and another element
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String]
}

extension SwiftInterfaceElement {
    
    var description: String {
        description(incl: Set(SwiftInterfaceElementDescriptionToken.allCases))
    }
    
    func description(excl: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        let includedTokens = Set(SwiftInterfaceElementDescriptionToken.allCases).subtracting(excl)
        return description(incl: includedTokens)
    }
}

extension SwiftInterfaceElement {

    func setupParentRelationships(parent: (any SwiftInterfaceElement)? = nil) {
        self.parent = parent
        children.forEach {
            $0.setupParentRelationships(parent: self)
        }
    }

    /// The path to the parent based on the `pathComponentName`
    ///
    /// The path does not including the own `pathComponentName`
    ///
    /// - Important: `SwiftInterfaceExtension`'s parentPath is always the `extendedType`
    /// of the element to group them under the extended element
    var parentPath: String {
        if let extensionElement = self as? SwiftInterfaceExtension {
            // We want to group all extensions under the type that they are extending
            // so we return the extended type as the parent
            return sanitized(
                parentPath: extensionElement.extendedType
            )
        }

        var parent = self.parent
        var path = [parent?.pathComponentName]

        while parent != nil {
            parent = parent?.parent
            path += [parent?.pathComponentName]
        }

        return sanitized(
            parentPath: path.compactMap { $0 }.filter { !$0.isEmpty }.reversed().joined(separator: ".")
        )
    }

    /// Removing module name prefix for nicer readability
    private func sanitized(parentPath: String) -> String {
        var sanitizedPathComponents = parentPath.components(separatedBy: ".")

        // The first path component is always the module name so it's safe to remove all prefixes
        if let moduleName = sanitizedPathComponents.first {
            while sanitizedPathComponents.first == moduleName {
                sanitizedPathComponents.removeFirst()
            }
        }

        return sanitizedPathComponents.joined(separator: ".")
    }
}

extension SwiftInterfaceElement {
    /// Checks whether or not 2 elements can be compared based on their `printedName`, `type` and `parentPath`
    ///
    /// If the `printedName`, `type` + `parentPath` is the same we can assume that it's the same element but altered
    /// We're using the `printedName` and not the `name` as for example there could be multiple functions with the same name but different parameters.
    /// In this specific case we want to find an exact match of the signature.
    ///
    /// e.g. if we have a function `init(foo: Int, bar: Int) -> Void` the `name` would be `init` and `printedName` would be `init(foo:bar:)`.
    /// If we used the `name` it could cause a false positive with other functions named `init` (e.g. convenience inits) when trying to find matching elements during this finding phase.
    /// In a later consolidation phase removals/additions are compared again based on their `name` to combine them to a `change`
    func isDiffable(with otherElement: any SwiftInterfaceElement) -> Bool {
        diffableSignature == otherElement.diffableSignature &&
            type(of: self) == type(of: otherElement) &&
            parentPath == otherElement.parentPath
    }
}

extension SwiftInterfaceElement {

    /// Produces the complete recursive description of the element
    func recursiveDescription(
        indentation: Int = 0,
        incl tokens: Set<SwiftInterfaceElementDescriptionToken> = Set(SwiftInterfaceElementDescriptionToken.allCases)
    ) -> String {
        let spacer = "  "
        var recursiveDescription = "\(indentedDescription(indentation: indentation, incl: tokens))"
        if !self.children.isEmpty {
            recursiveDescription.append(" {")
            for child in self.children.sorted(by: { $0.description(incl: tokens) < $1.description(incl: tokens) }) {
                recursiveDescription.append("\n\(child.recursiveDescription(indentation: indentation + 1, incl: tokens))")
            }
            recursiveDescription.append("\n\(String(repeating: spacer, count: indentation))}")
        }

        return recursiveDescription
    }
    
    func indentedDescription(indentation: Int, incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var components = description(incl: tokens).components(separatedBy: .newlines)
        for (index, component) in components.enumerated() {
            components[index] = "\(String(repeating: "  ", count: indentation))\(component)"
        }
        return components.joined(separator: "\n")
    }
}
