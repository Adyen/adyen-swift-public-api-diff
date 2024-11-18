//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

extension SwiftInterfaceSubscript {

    struct Parameter {

        let firstName: String

        /// optional second "internal" name - can be ignored
        let secondName: String?

        let type: String

        let defaultValue: String?

        var description: String {
            var description = [
                firstName,
                secondName
            ].compactMap { $0 }.joined(separator: " ")

            if description.isEmpty {
                description += "\(type)"
            } else {
                description += ": \(type)"
            }

            if let defaultValue {
                description += " = \(defaultValue)"
            }

            return description
        }
    }
}

class SwiftInterfaceSubscript: SwiftInterfaceElement {

    static var declType: SwiftInterfaceElementDeclType { .subscript }
    
    let name: String = "subscript"

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. <T>
    let genericParameterDescription: String?

    let parameters: [Parameter]

    let returnType: String

    /// e.g. where T : Equatable
    let genericWhereClauseDescription: String?

    let accessors: String?

    var pathComponentName: String { "" } // Not relevant as / no children

    let children: [any SwiftInterfaceElement] = []

    var parent: (any SwiftInterfaceElement)?

    var diffableSignature: String {
        "\(name)(\(parameters.map { "\($0.firstName):" }.joined()))"
    }

    var consolidatableName: String { name }

    var description: String { compileDescription() }

    init(
        attributes: [String],
        modifiers: [String],
        genericParameterDescription: String?,
        parameters: [Parameter],
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
        changes += diffDescription(propertyType: "parameter", oldValues: other.parameters.map(\.description), newValues: parameters.map(\.description)) // TODO: Maybe have a better way to show changes
        changes += diffDescription(propertyType: "return type", oldValue: other.returnType, newValue: returnType)
        changes += diffDescription(propertyType: "generic where clause", oldValue: other.genericWhereClauseDescription, newValue: genericWhereClauseDescription)
        changes += diffDescription(propertyType: "accessors", oldValue: other.accessors, newValue: accessors)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceSubscript {

    func compileDescription() -> String {
        var components = [String]()

        components += attributes
        components += modifiers

        components += [
            [
                "subscript",
                genericParameterDescription,
                "(\(parameters.map(\.description).joined(separator: ", ")))"
            ].compactMap { $0 }.joined()
        ]

        components += ["-> \(returnType)"]

        genericWhereClauseDescription.map { components += [$0] }

        accessors.map { components += ["{ \($0) }"] }

        return components.joined(separator: " ")
    }
}
