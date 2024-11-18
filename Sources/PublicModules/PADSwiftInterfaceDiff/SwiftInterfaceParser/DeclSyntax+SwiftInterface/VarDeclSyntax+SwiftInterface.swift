//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftParser
import SwiftSyntax

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/structdeclsyntax
extension VariableDeclSyntax {
    
    func toInterfaceElement() -> [SwiftInterfaceVar] {
       
        let declarationAttributes = self.attributes.sanitizedList
        let modifiers = self.modifiers.sanitizedList
        let bindingSpecifier = self.bindingSpecifier.trimmedDescription
 
        // Transforming:
        // - final public let a = 0, b = 1, c: Double = 5.0
        // Into:
        // - final public let a: Int = 0
        // - final public let b: Int = 1
        // - final public let c: Double = 5.0
        return bindings.map {
            var accessors = $0.accessorBlock?.sanitizedDescription
            if accessors == nil, bindingSpecifier == "let" {
                // If the accessors are missing and we have a let we can assume it's get only
                accessors = "get"
            }
            
            return SwiftInterfaceVar(
                attributes: declarationAttributes,
                modifiers: modifiers,
                bindingSpecifier: bindingSpecifier,
                name: $0.pattern.trimmedDescription,
                typeAnnotation: $0.typeAnnotation?.type.trimmedDescription ?? "UNKNOWN_TYPE",
                initializerValue: $0.initializer?.value.trimmedDescription,
                accessors: accessors
            )
        }
    }
}
