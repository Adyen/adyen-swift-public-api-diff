//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/enumcasedeclsyntax
extension EnumCaseDeclSyntax {
    
    func toInterfaceElement(children: [any SwiftInterfaceElement]) -> [SwiftInterfaceEnumCase] {

        let attributes = self.attributes.sanitizedList
        let modifiers = self.modifiers.sanitizedList
        
        return elements.map {
            SwiftInterfaceEnumCase(
                attributes: attributes,
                modifiers: modifiers,
                name: $0.name.trimmedDescription,
                parameters: $0.parameterClause?.parameters.map {
                    .init(
                        firstName: $0.firstName?.trimmedDescription,
                        secondName: $0.secondName?.trimmedDescription,
                        type: $0.type.trimmedDescription,
                        defaultValue: $0.defaultValue?.value.description
                    )
                },
                rawValue: $0.rawValue?.value.trimmedDescription
            )
        }
    }
}
