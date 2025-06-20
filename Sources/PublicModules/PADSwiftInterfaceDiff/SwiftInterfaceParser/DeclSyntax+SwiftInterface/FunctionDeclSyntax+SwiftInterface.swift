//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/functiondeclsyntax
extension FunctionDeclSyntax {

    func toInterfaceElement() -> SwiftInterfaceFunction {

        var effectSpecifiers = [String]()

        if let effects = signature.effectSpecifiers {
            if let asyncSpecifier = effects.asyncSpecifier {
                effectSpecifiers.append(asyncSpecifier.trimmedDescription)
            }
            if let throwsClause = effects.throwsClause {
                effectSpecifiers.append(throwsClause.trimmedDescription)
            }
        }

        let parameters: [SwiftInterfaceElementParameter] = self.signature.parameterClause.parameters.map {
            .init(
                attributes: $0.attributes.sanitizedList,
                firstName: $0.firstName.trimmedDescription,
                secondName: $0.secondName?.trimmedDescription,
                type: $0.type.trimmedDescription,
                defaultValue: $0.defaultValue?.value.trimmedDescription.sanitizingNewlinesAndSpaces
            )
        }

        return SwiftInterfaceFunction(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            parameters: parameters,
            effectSpecifiers: effectSpecifiers,
            returnType: signature.returnClause?.type.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
