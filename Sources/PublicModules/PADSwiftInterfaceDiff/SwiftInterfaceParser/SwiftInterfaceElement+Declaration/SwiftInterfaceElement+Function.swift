import Foundation

extension SwiftInterfaceFunction {
    
    struct Parameter {
        
        let firstName: String
        
        /// optional second "internal" name - can be ignored
        let secondName: String?
        
        let type: String
        
        let defaultValue: String?
        
        var description: String {
            var description = [
                firstName,
                secondName
            ].compactMap { $0 }.joined(separator: " ")
            
            if description.isEmpty {
                description += "\(type)"
            } else {
                description += ": \(type)"
            }
            
            if let defaultValue {
                description += " = \(defaultValue)"
            }
            
            return description
        }
    }
}

class SwiftInterfaceFunction: SwiftInterfaceElement {
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    let name: String
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    let parameters: [Parameter]
    
    /// e.g. async, throws, rethrows
    let effectSpecifiers: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    let returnType: String
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    var pathComponentName: String { name }
    
    /// A function does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var parent: (any SwiftInterfaceElement)? = nil
    
    var diffableSignature: String {
        "\(name)(\(parameters.map { "\($0.firstName):" }.joined()))"
    }
    
    var consolidatableName: String { name }
    
    var description: String { compileDescription() }
    
    init(
        attributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        parameters: [Parameter],
        effectSpecifiers: [String],
        returnType: String?,
        genericWhereClauseDescription: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.effectSpecifiers = effectSpecifiers
        self.returnType = returnType ?? "Swift.Void"
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

extension SwiftInterfaceFunction {
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(propertyType: "parameter", oldValues: other.parameters.map { $0.description }, newValues: parameters.map { $0.description }) // TODO: Maybe have a better way to show changes
        changes += diffDescription(propertyType: "effect", oldValues: other.effectSpecifiers, newValues: effectSpecifiers)
        changes += diffDescription(propertyType: "return type", oldValue: other.returnType, newValue: returnType)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceFunction {
    
    func compileDescription() -> String {
        var components = [String]()
        
        components += attributes
        components += modifiers
        components += ["func"]
        
        components += [
            [
                name,
                genericParameterDescription,
                "(\(parameters.map { $0.description }.joined(separator: ", ")))"
            ].compactMap { $0 }.joined()
        ]
        
        components += effectSpecifiers
        components += ["-> \(returnType)"]
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
