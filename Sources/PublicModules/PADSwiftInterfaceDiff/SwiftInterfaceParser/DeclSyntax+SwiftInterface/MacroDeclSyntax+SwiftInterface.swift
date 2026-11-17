//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import SwiftSyntax

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/macrodeclsyntax
extension MacroDeclSyntax {

    func toInterfaceElement() -> SwiftInterfaceMacro {

        let parameters: [SwiftInterfaceElementParameter] = self.signature.parameterClause.parameters.map {
            .init(
                attributes: $0.attributes.sanitizedList,
                firstName: $0.firstName.trimmedDescription,
                secondName: $0.secondName?.trimmedDescription,
                type: $0.type.trimmedDescription,
                defaultValue: $0.defaultValue?.value.trimmedDescription.sanitizingNewlinesAndSpaces
            )
        }

        return SwiftInterfaceMacro(
            // Role attributes (e.g. `@attached(peer, names: ...)`) can span multiple lines
            attributes: self.attributes.sanitizedList.map(\.sanitizingMacroDescription),
            modifiers: self.modifiers.sanitizedList,
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            parameters: parameters,
            returnType: signature.returnClause?.type.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription,
            definition: self.definition?.value.trimmedDescription.sanitizingMacroDescription
        )
    }
}

private extension String {

    /// Collapses whitespace so formatting differences don't show up as changes
    ///
    /// e.g. `#externalMacro(\n  module: "M",\n  type: "T"\n)` -> `#externalMacro(module: "M", type: "T")`
    var sanitizingMacroDescription: String {
        self
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\( ", with: "(", options: .regularExpression)
            .replacingOccurrences(of: " \\)", with: ")", options: .regularExpression)
    }
}
