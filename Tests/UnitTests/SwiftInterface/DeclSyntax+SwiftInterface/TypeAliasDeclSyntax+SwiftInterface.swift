import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/typealiasdeclsyntax-swift.struct
extension TypeAliasDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceTypeAlias {
        SwiftInterfaceTypeAlias(
            declarationAttributes: self.attributes.map { $0.trimmedDescription },
            modifiers: self.modifiers.map { $0.trimmedDescription },
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            initializerValue: self.initializer.value.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
