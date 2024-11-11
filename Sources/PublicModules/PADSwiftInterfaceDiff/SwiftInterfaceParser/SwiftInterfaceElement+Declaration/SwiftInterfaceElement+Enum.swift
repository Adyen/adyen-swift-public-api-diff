import Foundation
import PADCore

class SwiftInterfaceEnum: SwiftInterfaceExtendableElement {
    
    static var declType: SwiftInterfaceElementDeclType { .enum }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    let name: String
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    var inheritance: [String]?
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    var pathComponentName: String { name }
    
    var children: [any SwiftInterfaceElement]
    
    var parent: (any SwiftInterfaceElement)? = nil
    
    var diffableSignature: String { name }
    
    var consolidatableName: String { name }
    
    var description: String { compileDescription() }
    
    var typeName: String { name }
    
    init(
        attributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.attributes = attributes
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.inheritance = inheritance
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

extension SwiftInterfaceEnum {
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(propertyType: "inheritance", oldValues: other.inheritance, newValues: inheritance)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceEnum {
    
    func compileDescription() -> String {
        
        var components = [String]()
        
        components += attributes
        components += modifiers
        components += ["enum"]
        
        components += [{
            var components = [
                name,
                genericParameterDescription
            ].compactMap { $0 }.joined()
            
            if let inheritance, !inheritance.isEmpty {
                components += ": \(inheritance.joined(separator: ", "))"
            }
            
            return components
        }()]
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
