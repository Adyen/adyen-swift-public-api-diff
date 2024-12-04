//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceTypeAlias: SwiftInterfaceElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    let name: String

    /// e.g. <T>
    let genericParameterDescription: String?

    /// e.g. any Swift.Equatable
    let initializerValue: String

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    var pathComponentName: String { "" } // Not relevant as / no children

    let children: [any SwiftInterfaceElement] = []

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String { name }

    var consolidatableName: String { name }

    var description: String {
        compileDescription()
    }

    init(
        attributes: [String],
        modifiers: [String],
        name: String,
        genericParameterDescription: String?,
        initializerValue: String,
        genericWhereClauseDescription: String?
    ) {
        self.attributes = attributes
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.initializerValue = initializerValue
        self.modifiers = modifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

extension SwiftInterfaceTypeAlias {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(propertyType: "assignment", oldValue: other.initializerValue, newValue: initializerValue)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceTypeAlias {

    func compileDescription() -> String {
        var description = ""
        description.append(attributes.joined(separator: "\n"), with: "")
        description.append(modifiers.joined(separator: " "), with: "\n")
        description.append("typealias", with: " ")
        description.append(name, with: " ")
        description.append(genericParameterDescription, with: "")
        description.append(initializerValue, with: " ") { "= \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
