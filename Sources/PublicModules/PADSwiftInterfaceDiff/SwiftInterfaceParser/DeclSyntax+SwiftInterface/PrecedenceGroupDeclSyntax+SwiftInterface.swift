//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

extension PrecedenceGroupDeclSyntax {

    func toInterfaceElement() -> SwiftInterfacePrecedenceGroup {
        // Explicit defaults and omitted defaults describe the same API.
        var properties = ["associativity": "none", "assignment": "false"]
        for attribute in groupAttributes {
            if let associativity = attribute.as(PrecedenceGroupAssociativitySyntax.self) {
                properties["associativity"] = associativity.value.trimmedDescription
            } else if let assignment = attribute.as(PrecedenceGroupAssignmentSyntax.self) {
                properties["assignment"] = assignment.value.trimmedDescription
            } else if let relation = attribute.as(PrecedenceGroupRelationSyntax.self) {
                properties[relation.higherThanOrLowerThanLabel.trimmedDescription] =
                    relation.precedenceGroups.map { $0.name.trimmedDescription }.sorted().joined(separator: ", ")
            }
        }
        return SwiftInterfacePrecedenceGroup(name: name.trimmedDescription, properties: properties)
    }
}
