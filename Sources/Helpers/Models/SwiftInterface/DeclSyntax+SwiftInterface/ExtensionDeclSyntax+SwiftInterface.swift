import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/extensiondeclsyntax
extension ExtensionDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceExtension {
        return SwiftInterfaceExtension(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            extendedType: self.extendedType.trimmedDescription,
            inheritance: self.inheritanceClause?.inheritedTypes.sanitizedList,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            children: children
        )
    }
}
