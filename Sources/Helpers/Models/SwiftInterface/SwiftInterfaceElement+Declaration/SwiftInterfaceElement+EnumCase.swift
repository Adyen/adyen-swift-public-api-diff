import Foundation

extension SwiftInterfaceEnumCase {
    
    struct Parameter {
        
        let firstName: String?
        
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

class SwiftInterfaceEnumCase: SwiftInterfaceElement {
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    let name: String
    
    let parameters: [Parameter]?
    
    let rawValue: String?
    
    var childGroupName: String { "" }
    
    /// A typealias does not have children
    var children: [any SwiftInterfaceElement] = []
    
    var parent: (any SwiftInterfaceElement)? = nil
    
    var diffableSignature: String {
        name
    }
    
    var consolidatableName: String {
        name
    }
    
    var description: String {
        compileDescription()
    }
    
    init(
        attributes: [String],
        modifiers: [String],
        name: String,
        parameters: [Parameter]?,
        rawValue: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.name = name
        self.parameters = parameters
        self.rawValue = rawValue
    }
}

extension SwiftInterfaceEnumCase {
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "parameter", oldValues: other.parameters?.map { $0.description }, newValues: parameters?.map { $0.description }) // TODO: Maybe have a better way to show changes
        changes += diffDescription(propertyType: "raw value", oldValue: other.rawValue, newValue: rawValue)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceEnumCase {
    
    func compileDescription() -> String {

        var components = [String]()
        
        components += attributes
        components += modifiers
        components += ["case"]
        
        if let parameters {
            components += ["\(name)(\(parameters.map { $0.description }.joined(separator: ", ")))"]
        } else {
            components += [name]
        }
        
        return components.joined(separator: " ")
    }
}