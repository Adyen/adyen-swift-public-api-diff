//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADSwiftInterfaceDiff
import Testing

struct RepeatedParameterLabelTests {

    @Test func detectsChangeToSecondUnlabeledParameter() throws {
        let parser = SwiftInterfaceParser()
        let before = parser.parseValid(
            source: "public func combine(_ first: Int, _ second: Int)",
            moduleName: "Example"
        )
        let after = parser.parseValid(
            source: "public func combine(_ first: Int, _ second: String)",
            moduleName: "Example"
        )

        let changes = SwiftInterfaceAnalyzer().analyze(old: before, new: after)
        #expect(changes.count == 1)
        let change = try #require(changes.first)
        #expect(change.changeType.isModification)
        #expect(change.listOfChanges.count == 1)
        #expect(change.listOfChanges.first?.contains("Changed type from `Int` to `String`") == true)
    }
}
