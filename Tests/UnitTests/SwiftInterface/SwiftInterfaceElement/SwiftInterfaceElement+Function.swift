@testable import public_api_diff
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

struct SwiftInterfaceFunction: SwiftInterfaceElement {
    var type: SDKDump.DeclarationKind { .func }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
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
    
    /// A function does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var description: String {
        compileDescription()
    }
    
    init(
        declarationAttributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        parameters: [Parameter],
        effectSpecifiers: [String],
        returnType: String?,
        genericWhereClauseDescription: String?
    ) {
        self.declarationAttributes = declarationAttributes
        self.modifiers = modifiers
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.effectSpecifiers = effectSpecifiers
        self.returnType = returnType ?? "Swift.Void"
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

private extension SwiftInterfaceFunction {
    
    func compileDescription() -> String {
        var components = [String]()
        
        components += declarationAttributes
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
