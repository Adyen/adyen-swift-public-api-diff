import Foundation

class SwiftInterfaceTypeAlias: SwiftInterfaceElement {
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    let name: String
    
    /// e.g. <T>
    let genericParameterDescription: String?
    
    /// e.g. any Swift.Equatable
    let initializerValue: String
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?
    
    var childGroupName: String { "" } // Not relevant as only used to group children
    
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
        genericParameterDescription: String?,
        initializerValue: String,
        genericWhereClauseDescription: String?
    ) {
        self.attributes = attributes
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
        
        components += attributes
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
