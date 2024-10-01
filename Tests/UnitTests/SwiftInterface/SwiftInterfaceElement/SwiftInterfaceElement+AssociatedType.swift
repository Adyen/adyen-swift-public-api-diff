@testable import public_api_diff
import Foundation

struct SwiftInterfaceAssociatedType: SwiftInterfaceElement {
    
    var type: SDKDump.DeclarationKind { .struct }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
    let name: String
    
    let inheritance: [String]?
    
    /// e.g. any Swift.Equatable
    let initializerValue: String?
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    /// A associatedtype does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var description: String {
        compileDescription()
    }
    
    init(
        declarationAttributes: [String],
        modifiers: [String],
        name: String,
        inheritance: [String]?,
        initializerValue: String?,
        genericWhereClauseDescription: String?
    ) {
        self.declarationAttributes = declarationAttributes
        self.modifiers = modifiers
        self.name = name
        self.inheritance = inheritance
        self.initializerValue = initializerValue
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

private extension SwiftInterfaceAssociatedType {
    
    func compileDescription() -> String {
        
        var components = [String]()
        
        components += declarationAttributes
        components += modifiers
        components += ["associatedtype"]
        
        components += {
            // Joining name + inheritance without a space
            var components = [name]
            if let inheritance, !inheritance.isEmpty {
                components += [": \(inheritance.joined(separator: ", "))"]
            }
            return [components.joined()]
        }()
        
        initializerValue.map { components += ["= \($0)"] }
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
