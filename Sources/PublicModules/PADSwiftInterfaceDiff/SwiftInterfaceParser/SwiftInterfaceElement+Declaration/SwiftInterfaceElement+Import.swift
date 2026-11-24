//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

class SwiftInterfaceImport: SwiftInterfaceElement {

    var attributes: [String]
    let modifiers: [String]
    let kind: String?
    let path: String
    var parent: (any SwiftInterfaceElement)?
    let children: [any SwiftInterfaceElement] = []

    var pathComponentName: String { path }
    var diffableSignature: String { (["import", kind, path].compactMap { $0 }).joined(separator: " ") }
    var consolidatableName: String { diffableSignature }

    init(attributes: [String], modifiers: [String], kind: String?, path: String) {
        self.attributes = attributes
        self.modifiers = modifiers
        self.kind = kind
        self.path = path
    }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        let attributes = tokens.contains(.attributes) ? attributes : []
        let modifiers = tokens.contains(.modifiers) ? modifiers : []
        let declaration = (modifiers + [diffableSignature]).joined(separator: " ")
        return (attributes + [declaration]).joined(separator: "\n")
    }

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        guard let other = otherElement as? Self else { return [] }
        return diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
            + diffDescription(propertyType: "modifier", oldValues: other.modifiers, newValues: modifiers)
    }
}

extension SwiftInterfaceImport: SwiftInterfaceAttributedElement {}
