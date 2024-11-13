//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

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
