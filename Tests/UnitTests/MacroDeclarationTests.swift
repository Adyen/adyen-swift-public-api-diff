//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct MacroDeclarationTests {

    private func changes(from old: String, to new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }

    @Test func parsesMacroDeclaration() throws {
        let root = SwiftInterfaceParser().parse(
            source: """
            @freestanding(expression) public macro stringify<T>(_ value: T) -> (T, Swift.String) = #externalMacro(
              module: "ExampleMacros",
              type: "StringifyMacro"
            )
            """,
            moduleName: "Example"
        )

        let macro = try #require(root.children.first as? SwiftInterfaceMacro)
        #expect(macro.name == "stringify")
        #expect(macro.description == """
        @freestanding(expression)
        public macro stringify<T>(_ value: T) -> (T, Swift.String) = #externalMacro(module: "ExampleMacros", type: "StringifyMacro")
        """)
    }

    @Test func reportsAddedMacro() throws {
        let changes = changes(
            from: "",
            to: #"@attached(peer) public macro Guide(description: Swift.String) = #externalMacro(module: "M", type: "GuideMacro")"#
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType == .addition(description: """
        @attached(peer)
        public macro Guide(description: Swift.String) = #externalMacro(module: "M", type: "GuideMacro")
        """))
    }

    @Test func reportsRemovedMacro() throws {
        let changes = changes(
            from: #"@attached(accessor) public macro Entry() = #externalMacro(module: "M", type: "EntryMacro")"#,
            to: ""
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType == .removal(description: """
        @attached(accessor)
        public macro Entry() = #externalMacro(module: "M", type: "EntryMacro")
        """))
    }

    @Test func reportsAddedOverloadAsAddition() throws {
        let existing = #"@attached(peer) public macro Guide(description: Swift.String) = #externalMacro(module: "M", type: "GuideMacro")"#
        let changes = changes(
            from: existing,
            to: existing + "\n" + #"@attached(peer) public macro Guide(key: Swift.String, description: Swift.String) = #externalMacro(module: "M", type: "GuideMacro")"#
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        guard case let .addition(description) = change.changeType else {
            Issue.record("Expected an addition, got \(change.changeType)")
            return
        }
        #expect(description.contains("key: Swift.String,\n  description: Swift.String"))
    }

    @Test func describesChangedRoleAndParameterType() throws {
        let changes = changes(
            from: #"@attached(peer) public macro Guide(description: Swift.String) = #externalMacro(module: "M", type: "GuideMacro")"#,
            to: #"@attached(peer, names: prefixed(_)) public macro Guide(description: Swift.Int) = #externalMacro(module: "M", type: "GuideMacro")"#
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
        #expect(Set(change.listOfChanges) == [
            "Added attribute `@attached(peer, names: prefixed(_))`",
            "Removed attribute `@attached(peer)`",
            "Modified parameter `description`: Changed type from `Swift.String` to `Swift.Int`"
        ])
    }

    @Test func describesChangedDefinition() throws {
        let changes = changes(
            from: #"@freestanding(expression) public macro bundle() -> Foundation.Bundle = #externalMacro(module: "Old", type: "BundleMacro")"#,
            to: #"@freestanding(expression) public macro bundle() -> Foundation.Bundle = #externalMacro(module: "New", type: "BundleMacro")"#
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.listOfChanges == [
            #"Modified macro definition from `#externalMacro(module: "Old", type: "BundleMacro")` to `#externalMacro(module: "New", type: "BundleMacro")`"#
        ])
    }

    @Test func ignoresReformattedDefinition() {
        let changes = changes(
            from: #"@attached(accessor) public macro Entry() = #externalMacro(module: "M", type: "EntryMacro")"#,
            to: """
            @attached(accessor) public macro Entry() = #externalMacro(
              module: "M",
              type: "EntryMacro"
            )
            """
        )

        #expect(changes.isEmpty)
    }
}

extension MacroDeclarationTests {

    @Test func ignoresRenamedInternalParameterName() {
        let changes = changes(
            from: #"@freestanding(expression) public macro stringify<T>(_ value: T) -> T = #externalMacro(module: "M", type: "S")"#,
            to: #"@freestanding(expression) public macro stringify<T>(_ expression: T) -> T = #externalMacro(module: "M", type: "S")"#
        )

        #expect(changes.isEmpty)
    }
}
