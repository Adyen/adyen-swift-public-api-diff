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
    /// - Returns: A list of change descriptions caused by a value change
    func diffDescription(
        propertyType: String,
        oldValues: [String]?,
        newValues: [String]?
    ) -> [String] {

        guard let oldValues else {
            guard let newValues else { return [] }
            return newValues.map { "Added \(propertyType) `\($0.description)`" }
        }

        guard let newValues else {
            return oldValues.map { "Removed \(propertyType) `\($0.description)`" }
        }
        
        let old = Set(oldValues)
        let new = Set(newValues)
        let removed = old.subtracting(new)
        let added = new.subtracting(old)

        // A conformance whose only difference is its availability annotation is a changed availability,
        // not a removal + addition (see `AvailabilityInheritance.conformance`)
        let removedByConformance = Dictionary(grouping: removed, by: Self.conformanceName)
        let addedByConformance = Dictionary(grouping: added, by: Self.conformanceName)
        let changedAvailability = Set(removedByConformance.keys).intersection(addedByConformance.keys).filter {
            removedByConformance[$0]?.count == 1 && addedByConformance[$0]?.count == 1
        }

        let availabilityChanges = changedAvailability.sorted().compactMap { conformance -> String? in
            guard let oldValue = removedByConformance[conformance]?.first,
                  let newValue = addedByConformance[conformance]?.first else { return nil }
            return "Changed availability of conformance `\(conformance)` from `\(Self.conformanceAvailability(oldValue))` to `\(Self.conformanceAvailability(newValue))`"
        }

        return availabilityChanges + old.symmetricDifference(new)
            .filter { !changedAvailability.contains(Self.conformanceName($0)) }
            .map { "\(new.contains($0) ? "Added" : "Removed") \(propertyType) `\($0)`" }
    }

    private static func conformanceName(_ value: String) -> String {
        value.components(separatedBy: AvailabilityInheritance.conformanceAvailabilitySeparator).first ?? value
    }

    private static func conformanceAvailability(_ value: String) -> String {
        let parts = value.components(separatedBy: AvailabilityInheritance.conformanceAvailabilitySeparator)
        guard parts.count > 1 else { return "availability of the type" }
        return String(parts.dropFirst().joined(separator: AvailabilityInheritance.conformanceAvailabilitySeparator).dropLast(" */".count))
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
