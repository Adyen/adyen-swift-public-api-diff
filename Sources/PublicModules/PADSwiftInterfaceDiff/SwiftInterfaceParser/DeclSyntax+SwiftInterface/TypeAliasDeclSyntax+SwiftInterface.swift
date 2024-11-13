//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

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
