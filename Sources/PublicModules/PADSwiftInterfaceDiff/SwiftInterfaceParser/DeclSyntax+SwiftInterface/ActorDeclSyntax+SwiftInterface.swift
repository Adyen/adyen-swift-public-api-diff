import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/actordeclsyntax
extension ActorDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceActor {
        SwiftInterfaceActor(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            inheritance: self.inheritanceClause?.inheritedTypes.sanitizedList,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            children: children
        )
    }
}
