//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

/// The machine readable, versioned representation of a public api diff.
///
/// See `docs/public-api-diff.schema.v1.json` for the JSON Schema of format version 1.
///
/// ## Versioning
/// ``formatVersion`` only changes for breaking changes (a field is removed, renamed or changes its meaning,
/// or a new value is added to an enumeration such as ``ChangeRecord/Kind``).
/// Adding new optional fields does not change it - consumers must ignore unknown fields.
public struct JSONReport: Codable, Equatable {

    /// The format version produced by this version of the library
    public static let currentFormatVersion = 1

    public struct Tool: Codable, Equatable {
        public var name: String
        /// The version of the command line tool or `nil` if unknown
        public var version: String?

        public init(name: String = "public-api-diff", version: String?) {
            self.name = name
            self.version = version
        }

        enum CodingKeys: String, CodingKey { case name, version }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(version, forKey: .version) // Explicit `null`
        }
    }

    public struct Summary: Codable, Equatable {
        public var added: Int
        public var modified: Int
        public var removed: Int
        public var total: Int

        public init(added: Int, modified: Int, removed: Int) {
            self.added = added
            self.modified = modified
            self.removed = removed
            self.total = added + modified + removed
        }
    }

    public struct ChangeRecord: Codable, Equatable {

        public enum Kind: String, Codable, Equatable {
            case added
            case modified
            case removed
        }

        public var kind: Kind
        public var parentPath: String?
        public var before: String?
        public var after: String?
        public var details: [String]
        public var conditions: [String]

        public init(
            kind: Kind,
            parentPath: String?,
            before: String?,
            after: String?,
            details: [String],
            conditions: [String]
        ) {
            self.kind = kind
            self.parentPath = parentPath
            self.before = before
            self.after = after
            self.details = details
            self.conditions = conditions
        }

        enum CodingKeys: String, CodingKey { case kind, parentPath, before, after, details, conditions }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            try container.encode(parentPath, forKey: .parentPath) // Explicit `null`
            try container.encode(before, forKey: .before) // Explicit `null`
            try container.encode(after, forKey: .after) // Explicit `null`
            try container.encode(details, forKey: .details)
            try container.encode(conditions, forKey: .conditions)
        }
    }

    public var formatVersion: Int
    public var tool: Tool
    public var oldVersionName: String?
    public var newVersionName: String?
    public var platform: String?
    public var analyzedTargets: [String]?
    public var warnings: [String]
    public var summary: Summary
    public var targets: [String: [ChangeRecord]]

    public init(
        formatVersion: Int = JSONReport.currentFormatVersion,
        tool: Tool,
        oldVersionName: String?,
        newVersionName: String?,
        platform: String?,
        analyzedTargets: [String]?,
        warnings: [String],
        summary: Summary,
        targets: [String: [ChangeRecord]]
    ) {
        self.formatVersion = formatVersion
        self.tool = tool
        self.oldVersionName = oldVersionName
        self.newVersionName = newVersionName
        self.platform = platform
        self.analyzedTargets = analyzedTargets
        self.warnings = warnings
        self.summary = summary
        self.targets = targets
    }

    enum CodingKeys: String, CodingKey {
        case formatVersion, tool, oldVersionName, newVersionName, platform
        case analyzedTargets, warnings, summary, targets
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formatVersion, forKey: .formatVersion)
        try container.encode(tool, forKey: .tool)
        try container.encode(oldVersionName, forKey: .oldVersionName) // Explicit `null`
        try container.encode(newVersionName, forKey: .newVersionName) // Explicit `null`
        try container.encode(platform, forKey: .platform) // Explicit `null`
        try container.encode(analyzedTargets, forKey: .analyzedTargets) // Explicit `null`
        try container.encode(warnings, forKey: .warnings)
        try container.encode(summary, forKey: .summary)
        try container.encode(targets, forKey: .targets)
    }
}

/// Generates a deterministic, versioned JSON document (see ``JSONReport``) from the provided information
public struct JSONOutputGenerator: OutputGenerating {

    /// The version of the tool that is reported in the output (`nil` if unknown)
    public let toolVersion: String?

    /// - Parameter toolVersion: The version of the tool that is reported as `tool.version`
    public init(toolVersion: String? = nil) {
        self.toolVersion = toolVersion
    }

    /// Generates the JSON document as a `String` (UTF-8, pretty printed, sorted keys, no trailing newline)
    public func generate(
        from changesPerTarget: [String: [Change]],
        allTargets: [String]?,
        oldVersionName: String?,
        newVersionName: String?,
        platform: String?,
        warnings: [String]
    ) throws -> String {
        let report = makeReport(
            from: changesPerTarget,
            allTargets: allTargets,
            oldVersionName: oldVersionName,
            newVersionName: newVersionName,
            platform: platform,
            warnings: warnings
        )
        return try Self.encode(report)
    }

    /// Builds the ``JSONReport`` model (including the deterministic ordering) without encoding it
    public func makeReport(
        from changesPerTarget: [String: [Change]],
        allTargets: [String]?,
        oldVersionName: String?,
        newVersionName: String?,
        platform: String?,
        warnings: [String]
    ) -> JSONReport {

        var targets = [String: [JSONReport.ChangeRecord]]()
        for (targetName, changes) in changesPerTarget where !changes.isEmpty {
            targets[targetName] = changes.map(JSONReport.ChangeRecord.init).sorted(by: Self.isOrderedBefore)
        }

        let allRecords = targets.values.flatMap { $0 }

        return JSONReport(
            tool: .init(version: toolVersion),
            oldVersionName: oldVersionName,
            newVersionName: newVersionName,
            platform: platform,
            analyzedTargets: allTargets?.sorted(),
            warnings: warnings,
            summary: .init(
                added: allRecords.filter { $0.kind == .added }.count,
                modified: allRecords.filter { $0.kind == .modified }.count,
                removed: allRecords.filter { $0.kind == .removed }.count
            ),
            targets: targets
        )
    }

    /// Encodes a report using the canonical output formatting
    public static func encode(_ report: JSONReport) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(report)
        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - Privates

private extension JSONReport.ChangeRecord {

    init(_ change: Change) {
        let parentPath = change.parentPath.flatMap { $0.isEmpty ? nil : $0 }

        switch change.changeType {
        case let .addition(description):
            self.init(
                kind: .added, parentPath: parentPath, before: nil, after: description,
                details: change.listOfChanges, conditions: change.conditions
            )
        case let .removal(description):
            self.init(
                kind: .removed, parentPath: parentPath, before: description, after: nil,
                details: change.listOfChanges, conditions: change.conditions
            )
        case let .modification(oldDescription, newDescription):
            self.init(
                kind: .modified, parentPath: parentPath, before: oldDescription, after: newDescription,
                details: change.listOfChanges, conditions: change.conditions
            )
        }
    }

    var kindRank: Int {
        switch kind {
        case .added: 0
        case .modified: 1
        case .removed: 2
        }
    }
}

private extension JSONOutputGenerator {

    /// Total order: `parentPath` (`nil` first), `kind` (added, modified, removed), `after ?? before`, `before`, `details`, `conditions`
    static func isOrderedBefore(_ lhs: JSONReport.ChangeRecord, _ rhs: JSONReport.ChangeRecord) -> Bool {
        let comparisons: [ComparisonResult] = [
            compare(lhs.parentPath, rhs.parentPath),
            compare(lhs.kindRank, rhs.kindRank),
            compare(lhs.after ?? lhs.before, rhs.after ?? rhs.before),
            compare(lhs.before, rhs.before),
            compare(lhs.details.joined(separator: "\n"), rhs.details.joined(separator: "\n")),
            compare(lhs.conditions.joined(separator: "\n"), rhs.conditions.joined(separator: "\n"))
        ]

        guard let decisive = comparisons.first(where: { $0 != .orderedSame }) else { return false }
        return decisive == .orderedAscending
    }

    /// `nil` sorts before any value
    static func compare<T: Comparable>(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        switch (lhs, rhs) {
        case (nil, nil): return .orderedSame
        case (nil, _): return .orderedAscending
        case (_, nil): return .orderedDescending
        case let (lhs?, rhs?):
            if lhs == rhs { return .orderedSame }
            return lhs < rhs ? .orderedAscending : .orderedDescending
        }
    }
}
