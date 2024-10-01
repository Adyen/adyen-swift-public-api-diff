import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/enumdeclsyntax
extension EnumDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceEnum {
        SwiftInterfaceEnum(
            declarationAttributes: self.attributes.map { $0.trimmedDescription },
            modifiers: self.modifiers.map { $0.trimmedDescription },
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            inheritance: self.inheritanceClause?.inheritedTypes.map { $0.trimmedDescription },
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            children: children
        )
    }
}
