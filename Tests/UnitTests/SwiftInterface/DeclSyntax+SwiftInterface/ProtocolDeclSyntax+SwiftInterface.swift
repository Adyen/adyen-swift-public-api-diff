import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/protocoldeclsyntax
extension ProtocolDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceProtocol {
        SwiftInterfaceProtocol(
            declarationAttributes: self.attributes.map { $0.trimmedDescription },
            modifiers: self.modifiers.map { $0.trimmedDescription },
            name: self.name.trimmedDescription,
            primaryAssociatedTypes: self.primaryAssociatedTypeClause?.primaryAssociatedTypes.map { $0.name.trimmedDescription },
            inheritance: self.inheritanceClause?.inheritedTypes.map { $0.trimmedDescription },
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            children: children
        )
    }
}
