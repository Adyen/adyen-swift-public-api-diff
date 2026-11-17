//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct ParameterNameTests {

    @Test func internalParameterRenameDoesNotChangeCallSignature() {
        let changes = compare(
            "public func example(_ first: Int, label oldName: String)",
            "public func example(_ value: Int, label newName: String)"
        )
        #expect(changes.isEmpty)
    }

    @Test func externalParameterRenameStillChangesCallSignature() throws {
        let changes = compare(
            "public func example(first value: Int)",
            "public func example(second value: Int)"
        )
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
    }

    private func compare(_ old: String, _ new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
