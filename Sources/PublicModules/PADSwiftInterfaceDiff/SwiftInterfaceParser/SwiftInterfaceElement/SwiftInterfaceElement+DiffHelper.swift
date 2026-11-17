//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

extension SwiftInterfaceElement {

    /// Returns a description for a change between an old and new value
    /// - Parameters:
    ///   - propertyType: The (optional) property type name (e.g. "accessor", "modifier", "generic where clause", ...) for additional information
    ///   - oldValue: The (optional) old value
    ///   - newValue: The (optional) new value
    /// - Returns: A list with a single item that represents a change description caused by a value change
    func diffDescription(
        propertyType: String?,
        oldValue: String?,
        newValue: String?
    ) -> [String] {

        guard let changeType: ChangeType = .for(oldValue: oldValue, newValue: newValue) else { return [] }

        var diffDescription: String
        if let propertyType {
            diffDescription = "\(changeType.title) \(propertyType)"
        } else {
            diffDescription = "\(changeType.title)"
        }

        switch changeType {
        case let .modification(old, new):
            diffDescription += " from `\(old)` to `\(new)`"
        case let .removal(string):
            diffDescription += " `\(string)`"
        case let .addition(string):
            diffDescription += " `\(string)`"
        }

        return [diffDescription]
    }

    /// Returns a list of change descriptions for changes between the old and new values
    /// - Parameters:
    ///   - propertyType: The property type name (e.g. "accessor", "modifier", "generic where clause", ...)
    ///                   for additional information
    ///   - oldValues: The (optional) old values
    ///   - newValues: The (optional) new values
    ///   - oldTypeAttributes: For inheritance: the old attributes of the type (the availability of its conformances)
    ///   - newTypeAttributes: For inheritance: the new attributes of the type
    /// - Returns: A list of change descriptions caused by a value change
    func diffDescription(
        propertyType: String,
        oldValues: [String]?,
        newValues: [String]?,
        oldTypeAttributes: [String] = [],
        newTypeAttributes: [String] = []
    ) -> [String] {

        if propertyType == "attribute" {
            return Self.attributeDiffDescription(oldValues: oldValues ?? [], newValues: newValues ?? [])
        }

        guard let oldValues else {
            guard let newValues else { return [] }
            return newValues.map { Self.listEntryDescription("Added", propertyType, $0) }
        }

        guard let newValues else {
            return oldValues.map { Self.listEntryDescription("Removed", propertyType, $0) }
        }

        let old = Set(oldValues)
        let new = Set(newValues)
        let removed = old.subtracting(new)
        let added = new.subtracting(old)

        // A conformance whose only difference is its availability is a changed availability,
        // not a removal + addition (see `AvailabilityInheritance.conformance`)
        let removedByConformance = Dictionary(grouping: removed, by: Self.conformanceName)
        let addedByConformance = Dictionary(grouping: added, by: Self.conformanceName)
        let changedAvailability = Set(removedByConformance.keys).intersection(addedByConformance.keys).filter {
            removedByConformance[$0]?.count == 1 && addedByConformance[$0]?.count == 1
        }

        let availabilityChanges = changedAvailability.sorted().compactMap { conformance -> String? in
            guard let oldValue = removedByConformance[conformance]?.first,
                  let newValue = addedByConformance[conformance]?.first else { return nil }
            let oldAvailability = Self.conformanceAvailability(oldValue, typeAttributes: oldTypeAttributes)
            let newAvailability = Self.conformanceAvailability(newValue, typeAttributes: newTypeAttributes)
            guard let descriptions = AvailabilityChange.describe(old: oldAvailability, new: newAvailability) else {
                return "Changed availability of conformance `\(conformance)` from `\(oldAvailability.joined(separator: " "))` to `\(newAvailability.joined(separator: " "))`"
            }
            guard !descriptions.isEmpty else { return nil }
            return "Conformance `\(conformance)`: \(descriptions.joined(separator: "; "))"
        }

        return availabilityChanges + old.symmetricDifference(new)
            .filter { !changedAvailability.contains(Self.conformanceName($0)) }
            .map { Self.listEntryDescription(new.contains($0) ? "Added" : "Removed", propertyType, $0) }
    }

    /// Availability attributes are described per platform (e.g. `Availability added: macOS 27.3`),
    /// other attributes as added/removed
    private static func attributeDiffDescription(oldValues: [String], newValues: [String]) -> [String] {
        let isAvailability: (String) -> Bool = { $0.hasPrefix("@available(") }
        let oldAvailability = oldValues.filter(isAvailability)
        let newAvailability = newValues.filter(isAvailability)

        var descriptions = [String]()
        if Set(oldAvailability) != Set(newAvailability) {
            descriptions += AvailabilityChange.describe(old: oldAvailability, new: newAvailability)
                ?? listDiffDescription(propertyType: "attribute", old: oldAvailability, new: newAvailability)
        }
        return descriptions + listDiffDescription(
            propertyType: "attribute",
            old: oldValues.filter { !isAvailability($0) },
            new: newValues.filter { !isAvailability($0) }
        )
    }

    private static func listDiffDescription(propertyType: String, old: [String], new: [String]) -> [String] {
        let old = Set(old), new = Set(new)
        return old.symmetricDifference(new).map {
            "\(new.contains($0) ? "Added" : "Removed") \(propertyType) `\($0)`"
        }
    }

    /// e.g. "Added inheritance `Swift.Hashable` (available on iOS 27.3)" for a conformance with own availability
    private static func listEntryDescription(_ change: String, _ propertyType: String, _ value: String) -> String {
        let (conformance, availability) = AvailabilityInheritance.splitConformance(value)
        guard !availability.isEmpty else { return "\(change) \(propertyType) `\(value)`" }
        let summary = AvailabilityChange.summary(availability) ?? availability.joined(separator: " ")
        return "\(change) \(propertyType) `\(conformance)` (\(summary))"
    }

    private static func conformanceName(_ value: String) -> String {
        AvailabilityInheritance.splitConformance(value).conformance
    }

    /// The conformance's own availability, or the type's when it has none
    private static func conformanceAvailability(_ value: String, typeAttributes: [String]) -> [String] {
        let availability = AvailabilityInheritance.splitConformance(value).availability
        return availability.isEmpty ? typeAttributes.filter { $0.hasPrefix("@available(") } : availability
    }
}

// MARK: -

/// File-private helper to produce detailed descriptions
private enum ChangeType {
    case modification(old: String, new: String)
    case removal(String)
    case addition(String)

    var title: String {
        switch self {
        case .modification: "Modified"
        case .removal: "Removed"
        case .addition: "Added"
        }
    }

    static func `for`(oldValue: String?, newValue: String?) -> Self? {
        if oldValue == newValue { return nil }
        if let oldValue, let newValue { return .modification(old: oldValue, new: newValue) }
        if let oldValue { return .removal(oldValue) }
        if let newValue { return .addition(newValue) }
        return nil
    }
}
