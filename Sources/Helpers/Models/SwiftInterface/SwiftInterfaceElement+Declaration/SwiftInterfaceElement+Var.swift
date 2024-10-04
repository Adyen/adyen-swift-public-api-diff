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
    
    var children: [any SwiftInterfaceElement] = []
    
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

extension SwiftInterfaceVar {
    
    func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: nil, oldValue: other.bindingSpecifier, newValue: bindingSpecifier)
        changes += diffDescription(propertyType: "type", oldValue: other.typeAnnotation, newValue: typeAnnotation)
        changes += diffDescription(propertyType: "default value", oldValue: other.initializerValue, newValue: initializerValue)
        changes += diffDescription(propertyType: "accessors", oldValue: other.accessors, newValue: accessors)
        return changes.compactMap { $0 }
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
