import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/associatedtypedeclsyntax-swift.struct
extension AssociatedTypeDeclSyntax {
    
    func toInterfaceElement() -> SwiftInterfaceAssociatedType {
        SwiftInterfaceAssociatedType(
            declarationAttributes: self.attributes.map { $0.trimmedDescription },
            modifiers: self.modifiers.map { $0.trimmedDescription },
            name: self.name.trimmedDescription,
            inheritance: self.inheritanceClause?.inheritedTypes.map { $0.trimmedDescription },
            initializerValue: self.initializer?.value.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
