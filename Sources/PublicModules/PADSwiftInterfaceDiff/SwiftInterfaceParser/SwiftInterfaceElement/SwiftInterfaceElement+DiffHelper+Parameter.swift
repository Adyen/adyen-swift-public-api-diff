//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

extension SwiftInterfaceElement {
    
    /// Returns a list of change descriptions for changes between the old and new values
    /// - Parameters:
    ///   - propertyType: The property type name (e.g. "accessor", "modifier", "generic where clause", ...)
    ///                   for additional information
    ///   - oldParameters: The (optional) old parameters
    ///   - newParameters: The (optional) new parameters
    /// - Returns: A list of change descriptions caused by a value change
    func diffDescription(
        oldParameters: [SwiftInterfaceElementParameter]?,
        newParameters: [SwiftInterfaceElementParameter]?
    ) -> [String] {
        let propertyType = "parameter"
        
        guard let oldParameters else {
            guard let newParameters else { return [] }
            return newParameters.map { "Added \(propertyType) `\($0.description)`" }
        }

        guard let newParameters else {
            return oldParameters.map { "Removed \(propertyType) `\($0.description)`" }
        }
        
        let oldKeys = oldParameters.matchKeys
        let newKeys = newParameters.matchKeys
        let newKeySet = Set(newKeys)
        let oldParametersByKey = Dictionary(uniqueKeysWithValues: zip(oldKeys, oldParameters))

        var changes = [String]()
        let oldKeySet = Set(oldKeys)
        if oldKeys.filter(newKeySet.contains) != newKeys.filter(oldKeySet.contains) {
            changes.append("Reordered parameters")
        }

        for (key, parameter) in zip(oldKeys, oldParameters) where !newKeySet.contains(key) {
            changes.append("Removed \(propertyType) `\(parameter.description)`")
        }

        for (index, pair) in zip(newKeys, newParameters).enumerated() {
            let (key, newParameter) = pair
            guard let oldParameter = oldParametersByKey[key] else {
                changes.append("Added \(propertyType) `\(newParameter.description)`")
                continue
            }

            let modificationDiffPrefix = modificationDiffDescriptionPrefix(
                propertyType: propertyType,
                firstName: oldParameter.displayName,
                index: index
            )
            
            // Check if the type has changed
            if oldParameter.type != newParameter.type {
                changes.append("\(modificationDiffPrefix): Changed type from `\(oldParameter.type)` to `\(newParameter.type)`")
            }
            
            // Check if the default value has changed
            changes += diffDescription(
                propertyType: "default value",
                oldValue: oldParameter.defaultValue,
                newValue: newParameter.defaultValue
            ).map { "\(modificationDiffPrefix)`: \($0)" }
            
            // Check if the attributes did change
            changes += diffDescription(
                propertyType: "attribute",
                oldValues: oldParameter.attributes,
                newValues: newParameter.attributes
            ).map { "\(modificationDiffPrefix)`: \($0)" }
        }
        
        return changes
    }
}

fileprivate extension SwiftInterfaceElement {
    
    func modificationDiffDescriptionPrefix(
        propertyType: String,
        firstName: String?,
        index: Int
    ) -> String {
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        
        if let firstName {
            return "Modified \(propertyType) `\(firstName)`"
        } else {
            return "Modified \(ordinalFormatter.string(from: NSNumber(value: index+1)) ?? "\(index + 1)") \(propertyType)"
        }
    }
}

private struct ParameterMatchKey: Hashable {
    let label: String?
    let occurrence: Int
}

private extension [SwiftInterfaceElementParameter] {

    var matchKeys: [ParameterMatchKey] {
        var occurrences: [String: Int] = [:]
        return enumerated().map { index, parameter in
            guard let label = parameter.firstName else {
                return ParameterMatchKey(label: nil, occurrence: index)
            }
            let occurrence = occurrences[label, default: 0]
            occurrences[label] = occurrence + 1
            return ParameterMatchKey(label: label, occurrence: occurrence)
        }
    }
}
