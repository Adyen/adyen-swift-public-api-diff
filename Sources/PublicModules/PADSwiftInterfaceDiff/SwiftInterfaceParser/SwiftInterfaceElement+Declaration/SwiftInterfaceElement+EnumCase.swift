//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceEnumCase: SwiftInterfaceElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    let name: String

    let parameters: [SwiftInterfaceElementParameter]?

    let rawValue: String?

    var pathComponentName: String { "" } // Not relevant as / no children

    /// An enum case does not have children
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
        parameters: [SwiftInterfaceElementParameter]?,
        rawValue: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.name = name
        self.parameters = parameters
        self.rawValue = rawValue
    }
}

extension SwiftInterfaceEnumCase {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(oldParameters: other.parameters, newParameters: parameters)
        changes += diffDescription(propertyType: "raw value", oldValue: other.rawValue, newValue: rawValue)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceEnumCase {

    var parameterDescription: String? {
        guard let parameters else { return nil }
        return formattedParameterDescription(for: parameters.map(\.description))
    }
    
    func compileDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var description = ""
        var modifiers = modifiers
        if !tokens.contains(.modifiers) { modifiers = [] }
        var attributes = attributes
        if !tokens.contains(.attributes) { attributes = [] }
        description.append(attributes.joined(separator: "\n"), with: "")
        description.append(modifiers.joined(separator: " "), with: "\n")
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append("case", with: modifiers.isEmpty ? "" : " ")
        description.append(name, with: " ")
        description.append(parameterDescription, with: "") { "(\($0))" }
        return description
    }
}
