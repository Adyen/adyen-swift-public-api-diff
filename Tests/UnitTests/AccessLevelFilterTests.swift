//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

@Suite
struct AccessLevelFilterTests {

    @Test func addedPrivateAndInternalStoredPropertiesAreIgnored() {
        let changes = compare(
            old: "public struct Example { public let visible: Int }",
            new: """
            public struct Example {
                internal let hidden: Int
                private let secret: Int
                fileprivate var other: Int
                final private var validationChallenge: Foundation::Data?
                public let visible: Int
            }
            """
        )

        #expect(changes.isEmpty)
    }

    @Test func addedPublicPropertyIsStillReported() throws {
        let changes = compare(
            old: "public struct Example { internal let hidden: Int }",
            new: "public struct Example { internal let hidden: Int\n public let visible: Int }"
        )

        #expect(changes.count == 1)
        #expect(try #require(changes.first).changeType.isAddition)
    }

    @Test func privateSetterDoesNotHideProperty() {
        let changes = compare(
            old: "public struct Example {}",
            new: "public struct Example { public private(set) var value: Int }"
        )

        #expect(changes.count == 1)
    }

    @Test func membersOfHiddenTypeAreIgnored() {
        let changes = compare(
            old: "public struct Example {}",
            new: """
            public struct Example {
                internal struct Helper {
                    public var value: Int
                    public func other()
                }
                private enum State { case a, b }
            }
            """
        )

        #expect(changes.isEmpty)
    }

    @Test func topLevelInternalDeclarationsAreIgnored() {
        let changes = compare(
            old: "",
            new: "internal struct Helper {}\nprivate func helper()\nfileprivate class C {}"
        )

        #expect(changes.isEmpty)
    }

    @Test func hiddenExtensionIsIgnored() {
        let changes = compare(
            old: "public struct Example {}",
            new: "public struct Example {}\ninternal extension Example { public func helper() }"
        )

        #expect(changes.isEmpty)
    }

    @Test func implicitAccessOfEnumCasesAndProtocolRequirementsIsKept() {
        let changes = compare(
            old: "",
            new: """
            public enum E { case a }
            public protocol P { func f() }
            """
        )

        #expect(changes.count == 2)
    }

    @Test func usableFromInlineDeclarationsAreKept() {
        let changes = compare(
            old: "@frozen public struct Example {}",
            new: "@frozen public struct Example { @usableFromInline internal var storage: Int }"
        )

        #expect(changes.count == 1)
    }

    // MARK: - API scope

    @Test func packageScopeKeepsPackageDeclarations() {
        let changes = compare(
            old: "public struct Example {}",
            new: "public struct Example { package func shared() }",
            apiScope: .package
        )

        #expect(changes.count == 1)
    }

    @Test func publicScopeDropsPackageDeclarations() {
        let changes = compare(
            old: "public struct Example {}",
            new: "public struct Example { package func shared()\n package var value: Int }\npackage struct Other {}",
            apiScope: .public
        )

        #expect(changes.isEmpty)
    }

    @Test func publicScopeKeepsPublicDeclarations() {
        let changes = compare(
            old: "public struct Example {}",
            new: "public struct Example { public func visible()\n package func shared() }",
            apiScope: .public
        )

        #expect(changes.count == 1)
    }

    @Test func allScopeKeepsEverything() {
        let changes = compare(
            old: "public struct Example {}",
            new: "public struct Example { internal let hidden: Int\n package func shared() }",
            apiScope: .all
        )

        #expect(changes.count == 1)
    }

    @Test func defaultParsingDoesNotFilter() {
        let parser = SwiftInterfaceParser()
        let source = "public struct Example { internal let hidden: Int }"

        let tokens = Set(SwiftInterfaceElementDescriptionToken.allCases)
        let defaultDescription = parser.parse(source: source, moduleName: "Example").description(incl: tokens)

        #expect(defaultDescription.contains("hidden"))
        #expect(defaultDescription == parser.parse(source: source, moduleName: "Example", apiScope: .all).description(incl: tokens))
    }

    private func compare(old: String, new: String, apiScope: APIScope = .package) -> [PADCore.Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example", apiScope: apiScope),
            new: parser.parse(source: new, moduleName: "Example", apiScope: apiScope)
        )
    }
}
