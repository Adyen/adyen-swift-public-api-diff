import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/structdeclsyntax
extension VariableDeclSyntax {
    
    func toInterfaceElement() -> [SwiftInterfaceVar] {
       
        let declarationAttributes = self.attributes.sanitizedList
        let modifiers = self.modifiers.sanitizedList
        let bindingSpecifier = self.bindingSpecifier.trimmedDescription
        
        // Transforming:
        // - final public let a = 0, b = 1, c: Double = 5.0
        // Into:
        // - final public let a: Int = 0
        // - final public let b: Int = 1
        // - final public let c: Double = 5.0
        return bindings.map {
            return SwiftInterfaceVar(
                attributes: declarationAttributes,
                modifiers: modifiers,
                bindingSpecifier: bindingSpecifier,
                name: $0.pattern.trimmedDescription,
                typeAnnotation: $0.typeAnnotation?.type.trimmedDescription,
                initializerValue: $0.initializer?.value.trimmedDescription,
                accessors: $0.accessorBlock?.sanitizedDescription
            )
        }
    }
}
