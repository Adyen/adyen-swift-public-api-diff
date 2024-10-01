import Foundation

protocol SwiftInterfaceElement: CustomStringConvertible, Equatable, AnyObject {
    
    /// Used to group output together
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
    
    var parent: (any SwiftInterfaceElement)? { get set }
}

extension SwiftInterfaceElement {
    
    func setupParentRelationships(parent: (any SwiftInterfaceElement)? = nil) {
        self.parent = parent
        children.forEach {
            $0.setupParentRelationships(parent: self)
        }
    }
    
    var parentPath: String {
        var parent = self.parent
        var path = [parent?.childGroupName]
        
        while parent != nil {
            parent = parent?.parent
            path += [parent?.childGroupName]
        }
        
        var sanitizedPath = path.compactMap { $0 }
        
        if sanitizedPath.last == "TopLevel" {
            sanitizedPath.removeLast()
        }
        
        return sanitizedPath.reversed().joined(separator: ".")
    }
}

extension SwiftInterfaceElement {
    static func == (lhs: Self, rhs: Self) -> Bool {
        // The description is the unique representation of an element and thus used for the equality check
        lhs.description == rhs.description
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
        return recursiveDescription
    }
}

extension SwiftInterfaceElement {
    var isSpiInternal: Bool {
        description.range(of: "@_spi(") != nil
    }
}
