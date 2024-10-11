import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/typealiasdeclsyntax-swift.struct
extension TypeAliasDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceTypeAlias {
        SwiftInterfaceTypeAlias(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            initializerValue: self.initializer.value.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
