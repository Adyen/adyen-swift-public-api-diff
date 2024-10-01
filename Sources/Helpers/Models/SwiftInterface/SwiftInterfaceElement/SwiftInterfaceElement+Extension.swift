import Foundation

class SwiftInterfaceExtension: SwiftInterfaceElement {
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    let extendedType: String
    
    let inheritance: [String]?
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    // TODO: The extensions show up independently on the root - find a way so we can nest them inside the parent (find a way to find the parent)
    var childGroupName: String { extendedType } // Grouping in extended type
    
    /// The members, declarations, ... inside of the body of the struct
    let children: [any SwiftInterfaceElement]
    
    var parent: (any SwiftInterfaceElement)? = nil
    
    var diffableSignature: String {
        extendedType
    }
    
    var consolidatableName: String {
        extendedType
    }
    
    var description: String {
        compileDescription()
    }
    
    init(
        attributes: [String],
        modifiers: [String],
        extendedType: String,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.extendedType = extendedType
        self.inheritance = inheritance
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

private extension SwiftInterfaceExtension {
    
    func compileDescription() -> String {
        
        var components = [String]()
        
        components += attributes
        components += modifiers
        components += ["extension"]
        
        if let inheritance, !inheritance.isEmpty {
            components += ["\(extendedType): \(inheritance.joined(separator: ", "))"]
        } else {
            components += [extendedType]
        }
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
