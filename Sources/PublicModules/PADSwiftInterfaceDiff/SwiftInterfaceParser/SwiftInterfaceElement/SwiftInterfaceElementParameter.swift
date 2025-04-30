//
//  SwiftInterfaceElementParameter.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 30/04/2025.
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
        let names = [
            firstName,
            secondName
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
}
