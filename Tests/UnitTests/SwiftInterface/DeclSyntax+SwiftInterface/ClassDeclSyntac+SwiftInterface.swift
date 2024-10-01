import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/classdeclsyntax
extension ClassDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceClass {
        SwiftInterfaceClass(
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
