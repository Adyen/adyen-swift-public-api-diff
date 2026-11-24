//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

extension OperatorDeclSyntax {

    func toInterfaceElement() -> SwiftInterfaceOperator {
        SwiftInterfaceOperator(
            fixity: fixitySpecifier.trimmedDescription,
            name: name.trimmedDescription,
            precedenceGroup: operatorPrecedenceAndTypes?.precedenceGroup.trimmedDescription,
            designatedTypes: operatorPrecedenceAndTypes?.designatedTypes.map { $0.name.trimmedDescription }.sorted() ?? []
        )
    }
}
