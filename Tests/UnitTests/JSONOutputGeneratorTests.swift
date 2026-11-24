//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
@testable import PADCore
@testable import PADOutputGenerator
import Testing

@Suite
struct JSONOutputGeneratorTests {

    private func generate(
        _ changes: [String: [Change]] = [:],
        allTargets: [String]? = ["Target_1"],
        platform: String? = nil,
        warnings: [String] = [],
        toolVersion: String? = nil
    ) throws -> String {
        try JSONOutputGenerator(toolVersion: toolVersion).generate(
            from: changes,
            allTargets: allTargets,
            oldVersionName: "old_source",
            newVersionName: "new_source",
            platform: platform,
            warnings: warnings
        )
    }

    private func decode(_ json: String) throws -> JSONReport {
        try JSONDecoder().decode(JSONReport.self, from: Data(json.utf8))
    }

    @Test func noChangesSingleModule() throws {
        let report = try decode(generate())

        #expect(report.formatVersion == 1)
        #expect(report.tool.name == "public-api-diff")
        #expect(report.oldVersionName == "old_source")
        #expect(report.newVersionName == "new_source")
        #expect(report.analyzedTargets == ["Target_1"])
        #expect(report.summary == .init(added: 0, modified: 0, removed: 0))
        #expect(report.targets.isEmpty)
    }

    @Test func noAnalyzableTargets() throws {
        let report = try decode(generate(allTargets: []))
        #expect(report.analyzedTargets == [])
    }

    @Test func noTargetsProvided() throws {
        let json = try generate(allTargets: nil)
        #expect(try decode(json).analyzedTargets == nil)
        #expect(json.contains("\"analyzedTargets\" : null"))
    }

    @Test func warningsArePassedThrough() throws {
        let report = try decode(generate(warnings: ["Warning 1", "Warning 2"]))
        #expect(report.warnings == ["Warning 1", "Warning 2"])
    }

    @Test func optionalValuesAreExplicitNull() throws {
        let json = try generate(
            ["Target_1": [.init(changeType: .addition(description: "A"), parentPath: "")]],
            allTargets: nil
        )
        #expect(json.contains("\"platform\" : null"))
        #expect(json.contains("\"version\" : null"))
        #expect(json.contains("\"before\" : null"))
        #expect(json.contains("\"parentPath\" : null"))
    }

    @Test func toolVersionAndPlatform() throws {
        let report = try decode(generate(platform: "iOS", toolVersion: "1.2.3"))
        #expect(report.tool.version == "1.2.3")
        #expect(report.platform == "iOS")
    }

    @Test func changeKindsAreMapped() throws {
        let report = try decode(generate([
            "Target_1": [
                .init(changeType: .addition(description: "new"), parentPath: "Parent"),
                .init(changeType: .removal(description: "old"), parentPath: "Parent"),
                .init(
                    changeType: .modification(oldDescription: "before", newDescription: "after"),
                    parentPath: "Parent",
                    listOfChanges: ["b detail", "a detail"]
                )
            ]
        ]))

        let records = try #require(report.targets["Target_1"])
        #expect(records.map(\.kind) == [.added, .modified, .removed])
        #expect(records[0].before == nil && records[0].after == "new")
        #expect(records[1].before == "before" && records[1].after == "after")
        #expect(records[1].details == ["a detail", "b detail"]) // Sorted by `Change.init`
        #expect(records[2].before == "old" && records[2].after == nil)
        #expect(report.summary == .init(added: 1, modified: 1, removed: 1))
        #expect(report.summary.total == 3)
    }

    @Test func emptyParentPathBecomesNull() throws {
        let report = try decode(generate([
            "Target_1": [
                .init(changeType: .addition(description: "A"), parentPath: ""),
                .init(changeType: .addition(description: "B"), parentPath: nil),
                .init(changeType: .addition(description: "C"), parentPath: "Parent")
            ]
        ]))
        #expect(report.targets["Target_1"]?.map(\.parentPath) == [nil, nil, "Parent"])
    }

    @Test func conditionsArePassedThrough() throws {
        let report = try decode(generate([
            "Target_1": [.init(
                changeType: .addition(description: "A"),
                parentPath: nil,
                conditions: ["os(iOS)", "swift(>=6.0)"]
            )]
        ]))
        #expect(report.targets["Target_1"]?.first?.conditions == ["os(iOS)", "swift(>=6.0)"])
    }

    @Test func emptyTargetName() throws {
        let report = try decode(generate(["": [.init(changeType: .addition(description: "A"))]], allTargets: nil))
        #expect(report.targets[""]?.count == 1)
    }

    @Test func targetsWithoutChangesAreOmitted() throws {
        let report = try decode(generate(["Target_1": [], "Target_2": [.init(changeType: .removal(description: "A"))]]))
        #expect(Array(report.targets.keys) == ["Target_2"])
    }

    @Test func slashesAreNotEscaped() throws {
        let json = try generate(["Target_1": [.init(changeType: .addition(description: "a/b"))]])
        #expect(json.contains("\"after\" : \"a/b\""))
    }

    @Test func outputIsDeterministic() throws {
        let changes: [Change] = [
            .init(changeType: .removal(description: "z"), parentPath: "B"),
            .init(changeType: .addition(description: "y"), parentPath: "B"),
            .init(changeType: .addition(description: "x"), parentPath: "B"),
            .init(changeType: .modification(oldDescription: "m1", newDescription: "m2"), parentPath: "A"),
            .init(changeType: .addition(description: "same"), parentPath: nil, listOfChanges: ["2"]),
            .init(changeType: .addition(description: "same"), parentPath: nil, listOfChanges: ["1"]),
            .init(changeType: .addition(description: "same"), parentPath: nil, conditions: ["os(iOS)"])
        ]

        let reference = try generate(["Target_1": changes, "Target_2": changes.reversed()])

        for offset in 0..<changes.count {
            let rotated = Array(changes[offset...] + changes[..<offset])
            let output = try generate(["Target_2": rotated.reversed(), "Target_1": rotated])
            #expect(output == reference)
        }

        let records = try #require(decode(reference).targets["Target_1"])
        #expect(records.first?.parentPath == nil) // `nil` first
        #expect(records.map(\.parentPath).dropFirst(3) == ["A", "B", "B", "B"])
        #expect(records.suffix(3).map(\.kind) == [.added, .added, .removed])
    }

    @Test func outputHasNoTrailingNewline() throws {
        #expect(try !generate().hasSuffix("\n")) // `print` adds the one newline in the command line tool
    }
}
