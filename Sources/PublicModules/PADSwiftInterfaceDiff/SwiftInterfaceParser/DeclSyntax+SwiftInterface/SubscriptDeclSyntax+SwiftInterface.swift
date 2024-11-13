//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/subscriptdeclsyntax
extension SubscriptDeclSyntax {
    
    func toInterfaceElement() -> SwiftInterfaceSubscript {
        
        let parameters: [SwiftInterfaceSubscript.Parameter] = self.parameterClause.parameters.map {
            .init(
                firstName: $0.firstName.trimmedDescription,
                secondName: $0.secondName?.trimmedDescription,
                type: $0.type.trimmedDescription,
                defaultValue: $0.defaultValue?.value.trimmedDescription.sanitizingNewlinesAndSpaces
            )
        }
        
        return SwiftInterfaceSubscript(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            parameters: parameters,
            returnType: returnClause.type.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            accessors: self.accessorBlock?.sanitizedDescription
        )
    }
}
