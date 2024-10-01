@testable import public_api_diff
import Foundation

struct SwiftInterfaceProtocol: SwiftInterfaceElement {
    
    var type: SDKDump.DeclarationKind { .protocol }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
    let name: String
    
    let primaryAssociatedTypes: [String]?
    
    let inheritance: [String]?
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
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
        primaryAssociatedTypes: [String]?,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.declarationAttributes = declarationAttributes
        self.name = name
        self.primaryAssociatedTypes = primaryAssociatedTypes
        self.inheritance = inheritance
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

private extension SwiftInterfaceProtocol {
    
    func compileDescription() -> String {
        
        var components = [String]()
        
        components += declarationAttributes
        components += modifiers
        components += ["protocol"]
        
        components += [
            [
                name,
                primaryAssociatedTypes.map { "<\($0.joined(separator: ", "))>"}
            ].compactMap { $0 }.joined()
        ]
        
        if let inheritance, !inheritance.isEmpty {
            components += [": \(inheritance.joined(separator: ", "))"]
        }
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
