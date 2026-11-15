//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

struct SwiftInterfaceElementParameter {

    /// e.g. @discardableResult, @MainActor, @objc, @_spi(...), ...
    let attributes: [String]
    
    let firstName: String?

    /// optional second "internal" name - can be ignored
    let secondName: String?

    let type: String

    let defaultValue: String?

    var description: String {
        description(includingInternalName: true)
    }

    func description(includingInternalName: Bool) -> String {
        let names = [
            firstName,
            includingInternalName ? secondName : nil
        ].compactMap { $0 }
        
        var description = (attributes + names).joined(separator: " ")

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

extension SwiftInterfaceElementParameter {
    
    var valueForDiffableSignature: String {
        "\(firstName ?? "_"):"
    }
    
    /// A human-readable name for the parameter used in change descriptions.
    ///
    /// Prefers the external argument label, but falls back to the internal name
    /// when the label is omitted (`_`), e.g. `_ action: ...` is reported as `action`.
    var displayName: String? {
        if let firstName, firstName != "_" { return firstName }
        return secondName ?? firstName
    }
}
