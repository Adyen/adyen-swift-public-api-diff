import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/associatedtypedeclsyntax-swift.struct
extension AssociatedTypeDeclSyntax {
    
    func toInterfaceElement() -> SwiftInterfaceAssociatedType {
        SwiftInterfaceAssociatedType(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            inheritance: self.inheritanceClause?.inheritedTypes.sanitizedList,
            initializerValue: self.initializer?.value.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
