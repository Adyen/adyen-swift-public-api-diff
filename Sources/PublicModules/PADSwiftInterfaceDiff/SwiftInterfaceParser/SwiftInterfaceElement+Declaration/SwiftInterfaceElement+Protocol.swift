//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceProtocol: SwiftInterfaceExtendableElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    let name: String

    let primaryAssociatedTypes: [String]?

    var inheritance: [String]?

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    var pathComponentName: String { name }

    /// The members, declarations, ... inside of the body of the struct
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
        primaryAssociatedTypes: [String]?,
        inheritance: [String]?,
        genericWhereClauseDescription: String?,
        children: [any SwiftInterfaceElement]
    ) {
        self.attributes = attributes
        self.name = name
        self.primaryAssociatedTypes = primaryAssociatedTypes
        self.inheritance = inheritance
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.children = children
    }
}

extension SwiftInterfaceProtocol {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "primary associated type", oldValues: other.primaryAssociatedTypes, newValues: primaryAssociatedTypes)
        changes += diffDescription(propertyType: "inheritance", oldValues: other.inheritance, newValues: inheritance)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceProtocol {

    func compileDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var description = ""
        var modifiers = modifiers
        if !tokens.contains(.modifiers) { modifiers = [] }
        var attributes = attributes
        if !tokens.contains(.attributes) { attributes = [] }
        description.append(attributes.joined(separator: "\n"), with: "")
        description.append(modifiers.joined(separator: " "), with: "\n")
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append("protocol", with: modifiers.isEmpty ? "" : " ")
        description.append(name, with: " ")
        description.append(primaryAssociatedTypes.map { "<\($0.joined(separator: ", "))>" }, with: "")
        description.append(inheritance?.sorted().joined(separator: ", "), with: "") { ": \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
