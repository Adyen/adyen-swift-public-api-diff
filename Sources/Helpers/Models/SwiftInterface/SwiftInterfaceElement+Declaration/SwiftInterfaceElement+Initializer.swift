import Foundation

extension SwiftInterfaceInitializer {
    
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

class SwiftInterfaceInitializer: SwiftInterfaceElement {
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    let optionalMark: String?
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    let parameters: [Parameter]
    
    /// e.g. async, throws, rethrows
    let effectSpecifiers: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    var childGroupName: String { "" } // Not relevant as only used to group children
    
    /// A function does not have children
    var children: [any SwiftInterfaceElement] = []
    
    var parent: (any SwiftInterfaceElement)? = nil
    
    var diffableSignature: String {
        "init(\(parameters.map { "\($0.firstName):" }.joined()))"
    }
    
    var consolidatableName: String {
        "init"
    }
    
    var description: String {
        compileDescription()
    }
    
    init(
        attributes: [String],
        modifiers: [String],
        optionalMark: String?,
        genericParameterDescription: String?,
        parameters: [Parameter],
        effectSpecifiers: [String],
        genericWhereClauseDescription: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.optionalMark = optionalMark
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.effectSpecifiers = effectSpecifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

extension SwiftInterfaceInitializer {
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "optional mark", oldValue: other.optionalMark, newValue: optionalMark)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(propertyType: "parameter", oldValues: other.parameters.map { $0.description }, newValues: parameters.map { $0.description }) // TODO: Maybe have a better way to show changes
        changes += diffDescription(propertyType: "effect", oldValues: other.effectSpecifiers, newValues: effectSpecifiers)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceInitializer {
    
    func compileDescription() -> String {
        var components = [String]()
        
        components += attributes
        components += modifiers
        
        components += [
            [
                "init",
                optionalMark,
                genericParameterDescription,
                "(\(parameters.map { $0.description }.joined(separator: ", ")))"
            ].compactMap { $0 }.joined()
        ]
        
        components += effectSpecifiers
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
