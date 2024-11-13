//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/protocoldeclsyntax
extension ProtocolDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> SwiftInterfaceProtocol {
        SwiftInterfaceProtocol(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            primaryAssociatedTypes: self.primaryAssociatedTypeClause?.primaryAssociatedTypes.map(\.name.trimmedDescription),
            inheritance: self.inheritanceClause?.inheritedTypes.sanitizedList,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            children: children
        )
    }
}
