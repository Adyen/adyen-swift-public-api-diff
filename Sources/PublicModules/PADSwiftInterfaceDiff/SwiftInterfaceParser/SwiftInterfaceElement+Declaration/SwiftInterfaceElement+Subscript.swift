//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceSubscript: SwiftInterfaceElement {

    let name: String = "subscript"

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. <T>
    let genericParameterDescription: String?

    let parameters: [SwiftInterfaceElementParameter]

    let returnType: String

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    let accessors: String?

    var pathComponentName: String { "" } // Not relevant as / no children

    let children: [any SwiftInterfaceElement] = []

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String {
        "\(name)(\(parameters.map(\.valueForDiffableSignature).joined()))"
    }

    var consolidatableName: String { name }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        compileDescription(incl: tokens)
    }

    init(
        attributes: [String],
        modifiers: [String],
        genericParameterDescription: String?,
        parameters: [SwiftInterfaceElementParameter],
        returnType: String,
        genericWhereClauseDescription: String?,
        accessors: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.returnType = returnType
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.accessors = accessors
    }
}

extension SwiftInterfaceSubscript {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(oldParameters: other.parameters, newParameters: parameters)
        changes += diffDescription(propertyType: "return type", oldValue: other.returnType, newValue: returnType)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        changes += diffDescription(propertyType: "accessors", oldValue: other.accessors, newValue: accessors)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceSubscript {

    var parameterDescription: String {
        formattedParameterDescription(for: parameters.map(\.description))
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
        description.append("subscript", with: modifiers.isEmpty ? "" : " ")
        description.append(genericParameterDescription, with: "")
        description.append("(\(parameterDescription))", with: "")
        description.append(returnType, with: " ") { "-> \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        description.append(accessors, with: " ") { "{ \($0) }" }
        return description
    }
}
