@testable import public_api_diff
import Foundation

struct SwiftInterfaceTypeAlias: SwiftInterfaceElement {
    
    var type: SDKDump.DeclarationKind { .struct }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
    let name: String
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    /// e.g. any Swift.Equatable
    let initializerValue: String
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    /// A typealias does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var description: String {
        compileDescription()
    }
    
    init(
        declarationAttributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        initializerValue: String,
        genericWhereClauseDescription: String?
    ) {
        self.declarationAttributes = declarationAttributes
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.initializerValue = initializerValue
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

private extension SwiftInterfaceTypeAlias {
    
    func compileDescription() -> String {

        var components = [String]()
        
        components += declarationAttributes
        components += modifiers
        components += ["typealias"]
        
        components += [
            [
                name,
                genericParameterDescription
            ].compactMap { $0 }.joined()
        ]
        
        components += ["= \(initializerValue)"]
        
        genericWhereClauseDescription.map { components += [$0] }
        
        return components.joined(separator: " ")
    }
}
