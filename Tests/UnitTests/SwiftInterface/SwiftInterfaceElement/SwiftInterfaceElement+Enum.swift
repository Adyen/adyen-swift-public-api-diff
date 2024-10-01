@testable import public_api_diff
import Foundation

struct SwiftInterfaceEnum: SwiftInterfaceElement {
    
    var type: SDKDump.DeclarationKind { .enum }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    let name: String
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    let inheritance: [String]?
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    /// The members, declarations, ... inside of the body of the struct
    let children: [any SwiftInterfaceElement]
    
    var description: String {
        compileDescription()
    }
    
    init(
        declarationAttributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.declarationAttributes = declarationAttributes
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.inheritance = inheritance
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

private extension SwiftInterfaceEnum {
    
    func compileDescription() -> String {
        
        var components = [String]()
        
        components += declarationAttributes
        components += modifiers
        components += ["enum"]
        
        components += [
            [
                name,
                genericParameterDescription
            ].compactMap { $0 }.joined()
        ]
        
        if let inheritance, !inheritance.isEmpty {
            components += [": \(inheritance.joined(separator: ", "))"]
        }
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
