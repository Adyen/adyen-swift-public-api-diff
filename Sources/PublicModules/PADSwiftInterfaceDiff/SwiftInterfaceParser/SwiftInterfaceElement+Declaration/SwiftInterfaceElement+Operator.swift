//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

class SwiftInterfaceOperator: SwiftInterfaceElement {

    let fixity: String
    let name: String
    let precedenceGroup: String?
    let designatedTypes: [String]
    var attributes: [String] = []
    var parent: (any SwiftInterfaceElement)?
    let children: [any SwiftInterfaceElement] = []

    var pathComponentName: String { name }
    var diffableSignature: String { "\(fixity) operator \(name)" }
    var consolidatableName: String { diffableSignature }

    init(fixity: String, name: String, precedenceGroup: String?, designatedTypes: [String]) {
        self.fixity = fixity
        self.name = name
        self.precedenceGroup = precedenceGroup
        self.designatedTypes = designatedTypes
    }

    func description(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String {
        var declaration = diffableSignature
        if let precedenceGroup {
            declaration += ": " + ([precedenceGroup] + designatedTypes).joined(separator: ", ")
        }
        let attributes = tokens.contains(.attributes) ? attributes : []
        return (attributes + [declaration]).joined(separator: "\n")
    }

    func differences(to otherElement: some SwiftInterfaceElement) -> [String] {
        guard let other = otherElement as? Self else { return [] }
        return diffDescription(propertyType: "attribute", oldValues: other.attributes, newValues: attributes)
            + diffDescription(propertyType: "precedence group", oldValue: other.precedenceGroup, newValue: precedenceGroup)
            + diffDescription(propertyType: "designated type", oldValues: other.designatedTypes, newValues: designatedTypes)
    }
}

extension SwiftInterfaceOperator: SwiftInterfaceAttributedElement {}
