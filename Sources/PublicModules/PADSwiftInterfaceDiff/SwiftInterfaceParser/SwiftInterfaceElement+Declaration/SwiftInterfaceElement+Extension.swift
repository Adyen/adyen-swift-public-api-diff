//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceExtension: SwiftInterfaceElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    let extendedType: String

    let inheritance: [String]?

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    var pathComponentName: String {
        [extendedType, genericWhereClauseDescription.map { "[\($0)]" }].compactMap { $0 }.joined()
    }

    /// The members, declarations, ... inside of the body of the struct
    var children: [any SwiftInterfaceElement]

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String { extendedType }

    var consolidatableName: String { extendedType }

    var description: String {
        compileDescription()
    }

    init(
        attributes: [String],
        modifiers: [String],
        extendedType: String,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.extendedType = extendedType
        self.inheritance = inheritance
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

extension SwiftInterfaceExtension {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "inheritance", oldValues: other.inheritance, newValues: inheritance)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceExtension {

    func compileDescription() -> String {
        var description = ""
        description.append(attributes.joined(separator: "\n"), with: "")
        description.append(modifiers.joined(separator: " "), with: "\n")
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append("extension", with: modifiers.isEmpty ? "" : " ")
        description.append(extendedType, with: " ")
        description.append(inheritance?.sorted().joined(separator: ", "), with: "") { ": \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
