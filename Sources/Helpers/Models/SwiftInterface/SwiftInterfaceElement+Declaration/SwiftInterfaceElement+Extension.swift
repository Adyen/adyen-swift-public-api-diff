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
    
    var childGroupName: String { extendedType } // Grouping by extended type
    
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

extension SwiftInterfaceExtension {
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "inheritance", oldValues: other.inheritance, newValues: inheritance)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
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
