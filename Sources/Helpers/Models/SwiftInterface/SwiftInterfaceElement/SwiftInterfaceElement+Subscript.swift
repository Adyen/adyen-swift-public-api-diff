import Foundation

extension SwiftInterfaceSubscript {
    
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

class SwiftInterfaceSubscript: SwiftInterfaceElement {
    
    let name: String = "subscript"
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    let parameters: [Parameter]
    
    let returnType: String
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    let accessors: String?
    
    var childGroupName: String { "" }
    
    /// A function does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var parent: (any SwiftInterfaceElement)? = nil
    
    var diffableSignature: String {
        parameters.description
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
        genericParameterDescription: String?,
        parameters: [Parameter],
        returnType: String,
        genericWhereClauseDescription: String?,
        accessors: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.returnType = returnType
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.accessors = accessors
    }
}

private extension SwiftInterfaceSubscript {
    
    func compileDescription() -> String {
        var components = [String]()
        
        components += attributes
        components += modifiers
        
        components += [
            [
                "subscript",
                genericParameterDescription,
                "(\(parameters.map { $0.description }.joined(separator: ", ")))"
            ].compactMap { $0 }.joined()
        ]
        
        components += ["-> \(returnType)"]
        
        genericWhereClauseDescription.map { components += [$0] }
        
        accessors.map { components += ["{ \($0) }"] }
        
        return components.joined(separator: " ")
    }
}
