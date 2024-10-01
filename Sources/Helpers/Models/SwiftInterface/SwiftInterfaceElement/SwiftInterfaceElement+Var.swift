import Foundation

class SwiftInterfaceVar: SwiftInterfaceElement {
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. let | var | inout | _mutating | _borrowing | _consuming
    let bindingSpecifier: String
    
    let name: String
    
    let typeAnnotation: String
    
    let initializerValue: String?
    
    let accessors: String?
    
    var childGroupName: String { "" } // Not relevant as only used to group children
    
    /// A var does not have children
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
        bindingSpecifier: String,
        name: String,
        typeAnnotation: String?,
        initializerValue: String?,
        accessors: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.bindingSpecifier = bindingSpecifier
        self.name = name
        self.typeAnnotation = typeAnnotation ?? "UNKNOWN_TYPE"
        self.initializerValue = initializerValue
        self.accessors = accessors
    }
}

private extension SwiftInterfaceVar {
    
    func compileDescription() -> String {
        
        var components = [String]()
        
        components += attributes
        components += modifiers
        components += [bindingSpecifier]
        components += ["\(name): \(typeAnnotation)"]

        initializerValue.map { components += ["= \($0)"] }
        accessors.map { components += ["{ \($0) }"] }
        
        return components.joined(separator: " ")
    }
}
