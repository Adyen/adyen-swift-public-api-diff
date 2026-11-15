//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Rendering of conformances whose availability differs from the type's own
/// (see `AvailabilityInheritance.conformance(_:declaredWith:on:)`).
///
/// Swift has no syntax for availability on a single entry of an inheritance clause,
/// so these conformances are rendered the way the interface declares them: as an extension.
///
/// ```
/// @available(iOS 16.1, *)
/// public enum ActivityStyle
///
/// @available(iOS 16.1, macOS 27.3, *)
/// extension ActivityStyle: Swift.Equatable
/// ```
protocol SwiftInterfaceConformingElement: SwiftInterfaceElement {

    /// Types/Protocols the element inherits from (conformances can carry their own availability)
    var inheritance: [String]? { get }

    /// The type named in a rendered conformance extension (`extension <name>: Conformance`)
    var conformingTypeName: String { get }

    /// The generic where clause of a rendered conformance extension
    var conformanceGenericWhereClause: String? { get }
}

extension SwiftInterfaceExtendableElement {

    var conformingTypeName: String {
        [parentPath, typeName].filter { !$0.isEmpty }.joined(separator: ".")
    }

    var conformanceGenericWhereClause: String? { nil }
}

extension SwiftInterfaceConformingElement {

    /// The inheritance clause without conformances that have their own availability
    var inheritanceClauseDescription: String? {
        let conformances = (inheritance ?? [])
            .map(AvailabilityInheritance.splitConformance)
            .filter(\.availability.isEmpty)
            .map(\.conformance)
        return conformances.isEmpty ? nil : conformances.sorted().joined(separator: ", ")
    }

    /// The conformances with their own availability, rendered as extensions (prefixed with a blank line)
    func conformanceExtensionsDescription(incl tokens: Set<SwiftInterfaceElementDescriptionToken>) -> String? {
        let conformances = (inheritance ?? [])
            .map(AvailabilityInheritance.splitConformance)
            .filter { !$0.availability.isEmpty }
            .sorted { $0.conformance < $1.conformance }
        guard !conformances.isEmpty else { return nil }

        let whereClause = conformanceGenericWhereClause.map { " \($0)" } ?? ""
        return conformances.map { conformance in
            let attributes = tokens.contains(.attributes) ? conformance.availability : []
            return (attributes + ["extension \(conformingTypeName): \(conformance.conformance)\(whereClause)"]).joined(separator: "\n")
        }
        .map { "\n\n\($0)" }
        .joined()
    }
}
