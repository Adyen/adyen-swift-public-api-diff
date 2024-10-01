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
    let children: [any SwiftInterfaceElement] = []
    
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
