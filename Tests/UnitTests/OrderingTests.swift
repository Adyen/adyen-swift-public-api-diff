//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct OrderingTests {

    @Test func availabilityAttributeAndPlatformOrderDoesNotChangeAPI() {
        let changes = compare(
            """
            @available(iOS 18.0, macOS 15.0, *)
            @available(tvOS, unavailable)
            public func example()
            """,
            """
            @available(tvOS, unavailable)
            @available(macOS 15.0, iOS 18.0, *)
            public func example()
            """
        )
        #expect(changes.isEmpty)
    }

    @Test func versionChangeStillReported() throws {
        let changes = compare(
            "@available(iOS 18.0, macOS 15.0, *) public func example()",
            "@available(macOS 15.0, iOS 19.0, *) public func example()"
        )
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
    }

    @Test func parameterReorderingIsReported() throws {
        let changes = compare(
            "public func example(first: Int, second: String)",
            "public func example(second: String, first: Int)"
        )
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
        #expect(change.listOfChanges.contains("Reordered parameters"))
    }

    private func compare(_ old: String, _ new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
