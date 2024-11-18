//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

class SwiftInterfaceAssociatedType: SwiftInterfaceElement {

    static var declType: SwiftInterfaceElementDeclType { .associatedtype }
    
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

    var description: String { compileDescription() }

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

    func compileDescription() -> String {

        var components = [String]()

        components += attributes
        components += modifiers
        components += ["associatedtype"]

        if let inheritance, !inheritance.isEmpty {
            components += ["\(name): \(inheritance.joined(separator: ", "))"]
        } else {
            components += [name]
        }

        initializerValue.map { components += ["= \($0)"] }

        genericWhereClauseDescription.map { components += [$0] }

        return components.joined(separator: " ")
    }
}
