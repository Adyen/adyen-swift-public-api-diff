//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceEnum: SwiftInterfaceExtendableElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    let name: String

    /// e.g. <T>
    let genericParameterDescription: String?

    var inheritance: [String]?

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    var pathComponentName: String { name }

    var children: [any SwiftInterfaceElement]

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String { name }

    var consolidatableName: String { name }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        compileDescription(incl: tokens)
    }

    var typeName: String { name }

    init(
        attributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.attributes = attributes
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.inheritance = inheritance
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

extension SwiftInterfaceEnum {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(propertyType: "inheritance", oldValues: other.inheritance, newValues: inheritance)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceEnum {

    func compileDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var description = ""
        if tokens.contains(.attributes) {
            description.append(attributes.joined(separator: "\n"), with: "")
        }
        if tokens.contains(.modifiers) {
            description.append(modifiers.joined(separator: " "), with: "\n")
        }
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append("enum", with: modifiers.isEmpty ? "" : " ")
        description.append(name, with: " ")
        description.append(genericParameterDescription, with: "")
        description.append(inheritance?.sorted().joined(separator: ", "), with: "") { ": \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
