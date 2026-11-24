//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

extension ImportDeclSyntax {

    func toInterfaceElement() -> SwiftInterfaceImport {
        SwiftInterfaceImport(
            attributes: attributes.sanitizedList,
            modifiers: modifiers.sanitizedList,
            kind: importKindSpecifier?.trimmedDescription,
            path: path.map { $0.name.trimmedDescription }.joined(separator: ".")
        )
    }
}
