//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

class SwiftInterfaceVar: SwiftInterfaceElement {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]

    /// e.g. public, private, package, open, internal
    let modifiers: [String]

    /// e.g. let | var | inout | _mutating | _borrowing | _consuming
    let bindingSpecifier: String

    let name: String

    let typeAnnotation: String

    let initializerValue: String?

    let accessors: String?

    var pathComponentName: String { "" } // Not relevant as / no children

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
        bindingSpecifier: String,
        name: String,
        typeAnnotation: String,
        initializerValue: String?,
        accessors: String?
    ) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.bindingSpecifier = bindingSpecifier
        self.name = name
        self.typeAnnotation = typeAnnotation
        self.initializerValue = initializerValue
        self.accessors = accessors
    }
}

extension SwiftInterfaceVar {

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        var changes = [String?]()
        guard let other = otherElement as? Self else { return [] }
        changes += diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
        changes += diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
        changes += diffDescription(propertyType: nil, oldValue: other.bindingSpecifier, newValue: bindingSpecifier)
        changes += diffDescription(propertyType: "type", oldValue: other.typeAnnotation, newValue: typeAnnotation)
        changes += diffDescription(propertyType: "default value", oldValue: other.initializerValue, newValue: initializerValue)
        changes += diffDescription(propertyType: "accessors", oldValue: other.accessors, newValue: accessors)
        return changes.compactMap { $0 }
    }
}

private extension SwiftInterfaceVar {

    func compileDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var description = ""
        var modifiers = modifiers
        if !tokens.contains(.modifiers) { modifiers = [] }
        var attributes = attributes
        if !tokens.contains(.attributes) { attributes = [] }
        description.append(attributes.joined(separator: "\n"), with: "")
        description.append(modifiers.joined(separator: " "), with: "\n")
        if modifiers.isEmpty && !attributes.isEmpty { description.append("\n") }
        description.append(bindingSpecifier, with: modifiers.isEmpty ? "" : " ")
        description.append(name, with: " ")
        description.append(typeAnnotation, with: "") { ": \($0)" }
        description.append(initializerValue, with: " ") { "= \($0)" }
        description.append(accessors, with: " ") { "{ \($0) }" }
        return description
    }
}
