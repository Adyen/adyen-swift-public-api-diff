//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

class SwiftInterfacePrecedenceGroup: SwiftInterfaceElement {

    let name: String
    let properties: [String: String]
    var attributes: [String] = []
    var parent: (any SwiftInterfaceElement)?
    let children: [any SwiftInterfaceElement] = []

    var pathComponentName: String { name }
    var diffableSignature: String { "precedencegroup \(name)" }
    var consolidatableName: String { diffableSignature }

    init(name: String, properties: [String: String]) {
        self.name = name
        self.properties = properties
    }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        let attributes = tokens.contains(.attributes) ? attributes : []
        let header = (attributes + [diffableSignature]).joined(separator: "\n")
        let body = properties.keys.sorted().map { "  \($0): \(properties[$0]!)" }.joined(separator: "\n")
        return header + " {\n" + body + "\n}"
    }

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        guard let other = otherElement as? Self else { return [] }
        return diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
            + Set(properties.keys).union(other.properties.keys).sorted().flatMap {
                diffDescription(propertyType: $0, oldValue: other.properties[$0], newValue: properties[$0])
            }
    }
}

extension SwiftInterfacePrecedenceGroup: SwiftInterfaceAttributedElement {}
