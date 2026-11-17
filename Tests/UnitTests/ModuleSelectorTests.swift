//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

@Suite
struct ModuleSelectorTests {

    @Test func selectorSpellingAloneDoesNotChangeAPI() {
        let changes = compare(
            old: "extension Example.Widget { public func existing() }",
            new: "extension Example::Widget { public func existing() }"
        )

        #expect(changes.isEmpty)
    }

    @Test func addedMemberStillReported() throws {
        let changes = compare(
            old: "extension Example.Widget { public func existing() }",
            new: """
            extension Example::Widget {
                public func existing()
                public func added()
            }
            """
        )

        #expect(changes.count == 1)
        let change = try #require(changes.first)
        #expect(change.changeType.isAddition)
        #expect(change.parentPath == "Widget")
    }

    @Test func importedModuleInSignatureMatchesLegacyQualification() {
        let changes = compare(
            old: "import Other\npublic func widget() -> Other.Widget",
            new: "import Other\npublic func widget() -> Other::Widget"
        )

        #expect(changes.isEmpty)
    }

    @Test func nestedTypeInCurrentModuleMatchesLegacySpelling() {
        let changes = compare(
            old: "public func widget() -> Example.Container.Widget",
            new: "public func widget() -> Example::Container.Example::Widget"
        )

        #expect(changes.isEmpty)
    }

    @Test func locallyShadowedModuleNameRetainsDisambiguation() {
        let changes = compare(
            old: "public struct Example {}\nextension Example.Widget { public func existing() }",
            new: "public struct Example {}\nextension Example::Widget { public func existing() }"
        )

        #expect(changes.count > 0)
    }

    @Test func overlayRecognizesTransitivelyImportedModules() {
        let changes = compare(
            old: "@_exported import Example\npublic func convert(_ value: Input.Value) -> Output.Value?",
            new: "@_exported import Example\npublic func convert(_ value: Input::Value) -> Output::Value?"
        )
        #expect(changes.isEmpty)
    }

    @Test func overlayStillReportsChangesBetweenTransitiveModules() {
        let changes = compare(
            old: "@_exported import Example\npublic func convert() -> First.Value",
            new: "@_exported import Example\npublic func convert() -> Second::Value"
        )
        #expect(changes.count == 1)
        #expect(changes.first?.changeType.isModification == true)
    }

    @Test func differentModulesStillReported() {
        let changes = compare(
            old: "import First\npublic func widget() -> First.Widget",
            new: "import Second\npublic func widget() -> Second::Widget"
        )

        #expect(changes.count > 0)
    }

    private func compare(old: String, new: String) -> [PADCore.Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
