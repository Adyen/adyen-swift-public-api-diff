@testable import public_api_diff
import Foundation

struct SwiftInterfaceVar: SwiftInterfaceElement {
    
    var type: SDKDump.DeclarationKind { .struct }
    
    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let declarationAttributes: [String]
    
    /// e.g. public, private, package, open, internal
    let modifiers: [String]
    
    /// e.g. let | var | inout | _mutating | _borrowing | _consuming
    let bindingSpecifier: String
    
    let name: String
    
    let typeAnnotation: String
    
    let initializerValue: String?
    
    let accessors: String?
    
    /// A var does not have children
    let children: [any SwiftInterfaceElement] = []
    
    var description: String {
        compileDescription()
    }
    
    init(
        declarationAttributes: [String],
        modifiers: [String],
        bindingSpecifier: String,
        name: String,
        typeAnnotation: String?,
        initializerValue: String?,
        accessors: String?
    ) {
        self.declarationAttributes = declarationAttributes
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
        
        components += declarationAttributes
        components += modifiers
        components += [bindingSpecifier]
        components += ["\(name): \(typeAnnotation)"]

        initializerValue.map { components += ["= \($0)"] }
        accessors.map { components += ["{ \($0) }"] }
        
        return components.joined(separator: " ")
    }
}
