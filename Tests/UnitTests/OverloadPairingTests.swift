//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

/// Overloads that only differ in their parameter types share a diffable signature (e.g. `guide(_:)`)
/// and must still be compared with their own counterpart.
struct OverloadPairingTests {

    private func changes(from old: String, to new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }

    @Test func pairsChangedOverloadWithItsCounterpartInsteadOfUnchangedOverload() throws {
        let changes = changes(
            from: """
            public func guide(_ value: Swift.Int)
            public func guide(_ value: Swift.String)
            """,
            to: """
            public func guide(_ value: Swift.Int)
            @discardableResult public func guide(_ value: Swift.String)
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        guard case let .modification(oldDescription, newDescription) = change.changeType else {
            Issue.record("Expected a modification, got \(change.changeType)")
            return
        }
        #expect(oldDescription == "public func guide(_ value: Swift.String) -> Swift.Void")
        #expect(newDescription == "@discardableResult\npublic func guide(_ value: Swift.String) -> Swift.Void")
        #expect(change.listOfChanges == ["Added attribute `@discardableResult`"])
    }

    @Test func pairsEachChangedOverloadWithItsOwnCounterpart() throws {
        let changes = changes(
            from: """
            public func guide(_ value: Swift.Int)
            public func guide(_ value: Swift.String)
            """,
            to: """
            @discardableResult public func guide(_ value: Swift.Int)
            @discardableResult public func guide(_ value: Swift.String)
            """
        )

        #expect(changes.count == 2)
        for change in changes {
            #expect(change.listOfChanges == ["Added attribute `@discardableResult`"])
        }
    }

    @Test func pairsGenericMacroOverloadsWithTheirOwnCounterpart() throws {
        let changes = changes(
            from: """
            @attached(peer) public macro Guide<T>(description: Swift.String, _ guides: Example.GenerationGuide<T>...) = #externalMacro(module: "M", type: "GuideMacro")
            @attached(peer) public macro Guide<RegexOutput>(description: Swift.String, _ guides: Swift.Regex<RegexOutput>) = #externalMacro(module: "M", type: "GuideMacro")
            """,
            to: """
            @attached(peer) public macro Guide<RegexOutput>(description: Swift.String, _ guides: Swift.Regex<RegexOutput>) = #externalMacro(module: "N", type: "GuideMacro")
            @attached(peer) public macro Guide<T>(description: Swift.String, _ guides: Example.GenerationGuide<T>...) = #externalMacro(module: "N", type: "GuideMacro")
            """
        )

        #expect(changes.count == 2)
        for change in changes {
            #expect(change.listOfChanges == [
                #"Modified macro definition from `#externalMacro(module: "M", type: "GuideMacro")` to `#externalMacro(module: "N", type: "GuideMacro")`"#
            ])
        }
    }

    @Test func reportsRemovedOverloadWithoutPairingItWithRemainingOverload() throws {
        let changes = changes(
            from: """
            public func guide(_ value: Swift.Int)
            public func guide(_ value: Swift.String)
            """,
            to: """
            public func guide(_ value: Swift.Int)
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType == .removal(description: "public func guide(_ value: Swift.String) -> Swift.Void"))
    }

    @Test func pairingDoesNotDependOnDeclarationOrder() throws {
        let changes = changes(
            from: """
            public func guide(_ value: Swift.Int)
            """,
            to: """
            public func guide(_ value: Swift.String)
            @discardableResult public func guide(_ value: Swift.Int)
            """
        )

        #expect(changes.count == 2)
        let modification = try #require(changes.first { $0.changeType.isModification })
        #expect(modification.listOfChanges == ["Added attribute `@discardableResult`"])
        #expect(changes.contains { $0.changeType == .addition(description: "public func guide(_ value: Swift.String) -> Swift.Void") })
    }
}
