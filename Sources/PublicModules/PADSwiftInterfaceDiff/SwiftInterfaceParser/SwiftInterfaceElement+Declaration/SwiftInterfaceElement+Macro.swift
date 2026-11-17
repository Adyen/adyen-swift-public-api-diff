//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// A macro declaration, e.g.
///
/// ```swift
/// @freestanding(expression)
/// public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MyMacros", type: "StringifyMacro")
/// ```
class SwiftInterfaceMacro: SwiftInterfaceElement {

    /// e.g. @attached(peer, names: prefixed(`$`)), @freestanding(expression), @available(...)
    var attributes: [String]

    let name: String

    /// e.g. <T>
    let genericParameterDescription: String?

    let parameters: [SwiftInterfaceElementParameter]

    /// e.g. public, package
    let modifiers: [String]

    /// The result type of a freestanding expression macro (macros without a result type have none)
    let returnType: String?

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    /// e.g. #externalMacro(module: "MyMacros", type: "StringifyMacro")
    let definition: String?

    var pathComponentName: String { name }

    /// A macro does not have children
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
        name: String,
        genericParameterDescription: String?,
        parameters: [SwiftInterfaceElementParameter],
        returnType: String?,
        genericWhereClauseDescription: String?,
        definition: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.name = name
        self.genericParameterDescription = genericParameterDescription
        self.parameters = parameters
        self.returnType = returnType
        self.genericWhereClauseDescription = genericWhereClauseDescription
        self.definition = definition
    }
}

extension SwiftInterfaceMacro {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: "generic parameter description", oldValue: other.genericParameterDescription, newValue: genericParameterDescription)
        changes += diffDescription(oldParameters: other.parameters, newParameters: parameters)
        changes += diffDescription(propertyType: "return type", oldValue: other.returnType, newValue: returnType)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        changes += diffDescription(propertyType: "macro definition", oldValue: other.definition, newValue: definition)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceMacro {

    func parameterDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        formattedParameterDescription(for: parameters.map { $0.description(includingInternalName: tokens.contains(.internalParameterNames)) })
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
        description.append("macro", with: modifiers.isEmpty ? "" : " ")
        description.append(name, with: " ")
        description.append(genericParameterDescription, with: "")
        description.append("(\(parameterDescription(incl: tokens)))", with: "")
        description.append(returnType, with: " ") { "-> \($0)" }
        description.append(definition, with: " ") { "= \($0)" }
        description.append(genericWhereClauseDescription, with: " ")
        return description
    }
}
