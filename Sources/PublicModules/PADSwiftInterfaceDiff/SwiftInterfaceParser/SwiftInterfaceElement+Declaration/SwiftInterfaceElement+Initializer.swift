//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceInitializer: SwiftInterfaceElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    let optionalMark: String?

    /// e.g. <T>
    let genericParameterDescription: String?

    let parameters: [SwiftInterfaceFunction.Parameter]

    /// e.g. async, throws, rethrows
    let effectSpecifiers: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    var pathComponentName: String { "" } // Not relevant as / no children

    /// A initializer does not have children
    let children: [any SwiftInterfaceElement] = []

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String {
        "init(\(parameters.map { "\($0.firstName):" }.joined()))"
    }

    var consolidatableName: String { "init" }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        compileDescription(incl: tokens)
    }

    init(
        attributes: [String],
        modifiers: [String],
        optionalMark: String?,
        genericParameterDescription: String?,
        parameters: [SwiftInterfaceFunction.Parameter],
        effectSpecifiers: [String],
        genericWhereClauseDescription: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.optionalMark = optionalMark
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.effectSpecifiers = effectSpecifiers
        self.genericWhereClauseDescription = genericWhereClauseDescription
    }
}

extension SwiftInterfaceInitializer {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "optional mark", oldValue: other.optionalMark, newValue: optionalMark)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(propertyType: "parameter", oldValues: other.parameters.map(\.description), newValues: parameters.map(\.description)) // TODO: Maybe have a better way to show changes
        changes += diffDescription(propertyType: "effect", oldValues: other.effectSpecifiers, newValues: effectSpecifiers)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceInitializer {

    var parameterDescription: String {
        formattedParameterDescription(for: parameters.map(\.description))
    }
    
    func compileDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var description = ""
        if tokens.contains(.attributes) {
            description.append(attributes.joined(separator: "\n"), with: "")
        }
        if tokens.contains(.modifiers) {
            description.append(modifiers.joined(separator: " "), with: "\n")
        }
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append("init", with: modifiers.isEmpty ? "" : " ")
        description.append(optionalMark, with: "")
        description.append(genericParameterDescription, with: "")
        description.append("(\(parameterDescription))", with: "")
        description.append(effectSpecifiers.joined(separator: " "), with: " ")
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
