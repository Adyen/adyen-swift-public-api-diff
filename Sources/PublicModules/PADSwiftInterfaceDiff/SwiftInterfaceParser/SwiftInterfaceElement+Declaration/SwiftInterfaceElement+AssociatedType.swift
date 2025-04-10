//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceAssociatedType: SwiftInterfaceElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// The name of the element
    let name: String

    /// Types/Protocols the element inherits from
    let inheritance: [String]?

    /// e.g. any Swift.Equatable
    let initializerValue: String?

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    var pathComponentName: String { name }

    /// A associatedtype does not have children
    let children: [any SwiftInterfaceElement] = []

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String { name }

    var consolidatableName: String { name }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        compileDescription(incl: tokens)
    }

    init(
        attributes: [String],
        modifiers: [String],
        name: String,
        inheritance: [String]?,
        initializerValue: String?,
        genericWhereClauseDescription: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.name = name
        self.inheritance = inheritance
        self.initializerValue = initializerValue
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

extension SwiftInterfaceAssociatedType {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "inheritance", oldValues: other.inheritance, newValues: inheritance)
        changes += diffDescription(propertyType: "assignment", oldValue: other.initializerValue, newValue: initializerValue)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceAssociatedType {

    func compileDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var description = ""
        if tokens.contains(.attributes) {
            description.append(attributes.joined(separator: "\n"), with: "")
        }
        if tokens.contains(.modifiers) {
            description.append(modifiers.joined(separator: " "), with: "\n")
        }
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append("associatedtype", with: modifiers.isEmpty ? "" : " ")
        description.append(name, with: " ")
        description.append(inheritance?.sorted().joined(separator: ", "), with: "") { ": \($0)" }
        description.append(initializerValue, with: " ") { "= \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
