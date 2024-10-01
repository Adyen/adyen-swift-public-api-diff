@testable import public_api_diff
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

struct SwiftInterfaceEnumCase: SwiftInterfaceElement {
    
    var type: SDKDump.DeclarationKind { .case }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    let name: String
    
    let parameters: [Parameter]?
    
    let rawValue: String?
    
    /// A typealias does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var description: String {
        compileDescription()
    }
    
    init(
        declarationAttributes: [String],
        modifiers: [String],
        name: String,
        parameters: [Parameter]?,
        rawValue: String?
    ) {
        self.declarationAttributes = declarationAttributes
        self.modifiers = modifiers
        self.name = name
        self.parameters = parameters
        self.rawValue = rawValue
    }
}

private extension SwiftInterfaceEnumCase {
    
    func compileDescription() -> String {

        var components = [String]()
        
        components += declarationAttributes
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
