import Foundation

protocol SwiftInterfaceElement: CustomStringConvertible, AnyObject {
    
    /// Used to group children together
    var childGroupName: String { get }
    
    var description: String { get }
    
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
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String]
}

extension SwiftInterfaceElement {
    
    func setupParentRelationships(parent: (any SwiftInterfaceElement)? = nil) {
        self.parent = parent
        children.forEach {
            $0.setupParentRelationships(parent: self)
        }
    }
    
    var parentPath: String {
        if let extensionElement = self as? SwiftInterfaceExtension {
            // We want to group all extensions under the type that they are extending
            // so we return the extended type as the parent
            return sanitized(
                parentPath: extensionElement.extendedType
            )
        }
        
        var parent = self.parent
        var path = [parent?.childGroupName]
        
        while parent != nil {
            parent = parent?.parent
            path += [parent?.childGroupName]
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
        return parentPath == otherElement.parentPath && type(of: self) == type(of: otherElement) && diffableSignature == otherElement.diffableSignature
    }
}

extension SwiftInterfaceElement {
    func recursiveDescription(indentation: Int = 0) -> String {
        let spacer = "  "
        var recursiveDescription = "\(String(repeating: spacer, count: indentation))\(description)"
        if !self.children.isEmpty {
            recursiveDescription.append("\n\(String(repeating: spacer, count: indentation)){")
            for child in self.children {
                recursiveDescription.append("\n\(String(repeating: spacer, count: indentation))\(child.recursiveDescription(indentation: indentation + 1))")
            }
            recursiveDescription.append("\n\(String(repeating: spacer, count: indentation))}")
        }
        
        if indentation == 0 {
            recursiveDescription.append("\n")
        }
        
        return recursiveDescription
    }
}
