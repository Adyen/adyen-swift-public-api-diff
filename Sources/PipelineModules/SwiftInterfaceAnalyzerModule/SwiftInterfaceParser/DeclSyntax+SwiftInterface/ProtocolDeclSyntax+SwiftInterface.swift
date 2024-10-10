import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/protocoldeclsyntax
extension ProtocolDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceProtocol {
        SwiftInterfaceProtocol(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            primaryAssociatedTypes: self.primaryAssociatedTypeClause?.primaryAssociatedTypes.map { $0.name.trimmedDescription },
            inheritance: self.inheritanceClause?.inheritedTypes.sanitizedList,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            children: children
        )
    }
}
