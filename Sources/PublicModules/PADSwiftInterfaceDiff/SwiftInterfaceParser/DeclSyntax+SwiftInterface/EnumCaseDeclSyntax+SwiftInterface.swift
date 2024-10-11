import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/enumcasedeclsyntax
extension EnumCaseDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> [SwiftInterfaceEnumCase] {

        let attributes = self.attributes.sanitizedList
        let modifiers = self.modifiers.sanitizedList
        
        return elements.map {
            SwiftInterfaceEnumCase(
                attributes: attributes,
                modifiers: modifiers,
                name: $0.name.trimmedDescription,
                parameters: $0.parameterClause?.parameters.map {
                    .init(
                        firstName: $0.firstName?.trimmedDescription,
                        secondName: $0.secondName?.trimmedDescription,
                        type: $0.type.trimmedDescription,
                        defaultValue: $0.defaultValue?.value.description
                    )
                },
                rawValue: $0.rawValue?.value.trimmedDescription
            )
        }
    }
}