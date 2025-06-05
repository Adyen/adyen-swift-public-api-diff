//
//  SwiftInterfaceElement+DiffHelper+Parameter.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 30/04/2025.
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
        
        let oldParametersByName = oldParameters.indexedByFirstName
        let newParametersByName = newParameters.indexedByFirstName

        var changes = [String]()
        
        // Check for removed parameters
        oldParameters.enumerated().forEach { index, oldParameter in
            let oldFirstName = oldParameter.firstName ?? "Parameter \(index)"
            if newParametersByName[oldFirstName] == nil {
                changes.append("Removed \(propertyType) `\(oldParameter.description)`")
            }
        }
        
        // Check for added and modified parameters
        newParameters.enumerated().forEach { index, newParameter in
            
            let newFirstName = newParameter.firstName ?? "Parameter \(index)"
            
            guard let oldParameter = oldParametersByName[newFirstName] else {
                // Parameter was added
                changes.append("Added \(propertyType) `\(newParameter.description)`")
                return
            }
            
            let modificationDiffPrefix = modificationDiffDescriptionPrefix(
                propertyType: propertyType,
                firstName: oldParameter.firstName,
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

private extension [SwiftInterfaceElementParameter] {
    
    var indexedByFirstName: [String: SwiftInterfaceElementParameter] {
        Dictionary(
            uniqueKeysWithValues: self.enumerated().map {
                ($0.element.firstName ?? "Parameter \($0.offset)", $0.element)
            }
        )
    }
}
