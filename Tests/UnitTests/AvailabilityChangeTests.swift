//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct AvailabilityChangeTests {

    /// `ActivityKit.ActivityAuthorizationInfo` (iOS 27.2 → 27.3)
    @Test func platformsBecomingAvailable() {
        #expect(AvailabilityChange.describe(
            old: [
                "@available(iOS 16.1, *)",
                "@available(macCatalyst, unavailable)",
                "@available(macOS, unavailable)",
                "@available(tvOS, unavailable)",
                "@available(watchOS, unavailable)"
            ],
            new: [
                "@available(iOS 16.1, macCatalyst 27.3, macOS 27.3, *)",
                "@available(tvOS, unavailable)",
                "@available(watchOS, unavailable)"
            ]
        ) == ["Availability added: macOS 27.3, Mac Catalyst 27.3"])
    }

    @Test func introductionChanged() {
        #expect(AvailabilityChange.describe(
            old: ["@available(iOS 27.0, *)", "@available(macCatalyst, unavailable)"],
            new: ["@available(iOS 27.2, *)", "@available(macCatalyst, unavailable)"]
        ) == ["Availability changed: iOS 27.0 → 27.2"])
    }

    @Test func platformMarkedUnavailableAndUndeclared() {
        #expect(AvailabilityChange.describe(
            old: ["@available(iOS 16.0, tvOS 16.0, watchOS 9.0, *)"],
            new: ["@available(iOS 16.0, watchOS 9.0, *)", "@available(visionOS, unavailable)", "@available(tvOS, unavailable)"]
        ) == ["Marked unavailable: tvOS, visionOS"])

        #expect(AvailabilityChange.describe(
            old: ["@available(iOS 16.0, tvOS 16.0, *)"],
            new: ["@available(iOS 16.0, *)"]
        ) == ["Availability no longer declared: tvOS"])

        #expect(AvailabilityChange.describe(
            old: ["@available(iOS 16.0, *)", "@available(tvOS, unavailable)"],
            new: ["@available(iOS 16.0, *)"]
        ) == ["No longer marked unavailable: tvOS"])
    }

    @Test func deprecations() {
        #expect(AvailabilityChange.describe(
            old: [],
            new: ["@available(*, deprecated, message: \"Use default initializer\")"]
        ) == ["Deprecated: all platforms (\"Use default initializer\")"])

        #expect(AvailabilityChange.describe(
            old: ["@available(iOS, introduced: 13.0)"],
            new: ["@available(iOS, introduced: 13.0, deprecated: 27.0, renamed: \"newName(_:)\")"]
        ) == ["Deprecated: iOS 27.0 (renamed to \"newName(_:)\")"])

        #expect(AvailabilityChange.describe(
            old: ["@available(iOS, deprecated: 26.0, message: \"a\")"],
            new: ["@available(iOS, deprecated: 27.0, message: \"a\")"]
        ) == ["Deprecation changed: iOS 26.0 → 27.0"])

        #expect(AvailabilityChange.describe(
            old: ["@available(*, deprecated)"],
            new: []
        ) == ["No longer deprecated: all platforms"])
    }

    @Test func formattingOnlyChangeIsNoChange() {
        #expect(AvailabilityChange.describe(old: ["@available(iOS 16, *)"], new: ["@available(iOS 16.0, *)"]) == [])
    }

    @Test func unknownArgumentFallsBackToAttributeStrings() throws {
        #expect(AvailabilityChange.describe(old: [], new: ["@available(iOS, futureKeyword: 1)"]) == nil)

        let changes = compare(
            "public func example()",
            "@available(iOS, futureKeyword: 1)\npublic func example()"
        )
        #expect(changes.first?.listOfChanges == ["Added attribute `@available(iOS, futureKeyword: 1)`"])
    }

    @Test func nonAvailabilityAttributesAreStillListed() throws {
        let changes = compare(
            "@available(iOS 27.0, *)\npublic func example()",
            "@available(iOS 27.2, *)\n@discardableResult\npublic func example()"
        )
        let change = try #require(changes.first)
        #expect(Set(change.listOfChanges) == ["Availability changed: iOS 27.0 → 27.2", "Added attribute `@discardableResult`"])
    }

    @Test func noasyncAdditionAndRemovalAreReported() throws {
        let unrestricted = "public func example()"
        let restricted = "@available(*, noasync)\npublic func example()"

        let addition = try #require(compare(unrestricted, restricted).first)
        #expect(addition.changeType.isModification)
        #expect(addition.listOfChanges == ["Marked unavailable from async contexts: all platforms"])

        let removal = try #require(compare(restricted, unrestricted).first)
        #expect(removal.changeType.isModification)
        #expect(removal.listOfChanges == ["No longer unavailable from async contexts: all platforms"])
    }

    @Test func noasyncMessageChangeIsReported() throws {
        let changes = compare(
            "@available(*, noasync, message: \"Use first()\")\npublic func example()",
            "@available(*, noasync, message: \"Use second()\")\npublic func example()"
        )

        let change = try #require(changes.first)
        #expect(change.listOfChanges == [
            "Async unavailability message changed: all platforms: \"Use first()\" → \"Use second()\""
        ])
    }

    @Test func noasyncAndOtherAvailabilityChangesAreBothReported() throws {
        let changes = compare(
            "@available(iOS 16.0, *)\npublic func example()",
            "@available(iOS 17.0, *)\n@available(*, noasync)\npublic func example()"
        )

        let change = try #require(changes.first)
        #expect(Set(change.listOfChanges) == [
            "Availability changed: iOS 16.0 → 17.0",
            "Marked unavailable from async contexts: all platforms"
        ])
    }

    @Test func unchangedNoasyncIsNotReported() {
        let source = "@available(*, noasync, message: \"Use replacement()\")\npublic func example()"
        #expect(compare(source, source).isEmpty)
    }

    private func compare(_ old: String, _ new: String) -> [PADCore.Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
