//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct ExtensionMergeTests {

    private static let tabContent = """
    public protocol TabContent {}
    extension Example.TabContent {
      public func badge(_ count: Swift.Int) -> Swift.Int
    }
    """

    private static let tab = """
    public struct Tab {}
    """

    /// `extension Example.TabContent` must merge into `TabContent`, never be routed into `Tab`
    /// just because `Example.Tab` is a string prefix of `Example.TabContent`.
    @Test func declarationOrderOfPrefixSharingTypesDoesNotChangeAPI() {
        let changes = compare(
            Self.tabContent + "\n" + Self.tab,
            Self.tab + "\n" + Self.tabContent
        )
        #expect(changes.isEmpty)
    }

    /// Mirrors `Foundation.Locale.Components` (iOS 27.2 → 27.3): the extension of the nested type
    /// moves in front of the extension that declares the nested type.
    @Test func extensionOfNestedTypeDeclaredInLaterExtensionIsMerged() {
        let nestedTypeDeclaration = """
        public struct Locale {}
        extension Example.Locale {
          public struct Components {}
        }
        """
        let nestedTypeExtension = """
        extension Example.Locale.Components {
          public init(identifier: Swift.String)
        }
        """
        let changes = compare(
            nestedTypeDeclaration + "\n" + nestedTypeExtension,
            nestedTypeExtension + "\n" + nestedTypeDeclaration
        )
        #expect(changes.isEmpty)

        let root = SwiftInterfaceParser().parse(source: nestedTypeExtension + "\n" + nestedTypeDeclaration, moduleName: "Example")
        #expect(!root.children.contains { $0 is SwiftInterfaceExtension })
    }

    @Test func extensionMergesIntoNestedTypeBehindPrefixSharingSibling() {
        let source = """
        public struct Tab {}
        public struct TabView {
          public struct Style {}
        }
        extension Example.TabView.Style {
          public func apply()
        }
        """
        let root = SwiftInterfaceParser().parse(source: source, moduleName: "Example")
        #expect(!root.children.contains { $0 is SwiftInterfaceExtension })
    }

    @Test func availabilityChangeOnExtensionIsReported() throws {
        let changes = compare(
            """
            public struct S {}
            @available(iOS 26.0, *)
            extension Example.S {
              public func f()
            }
            """,
            """
            public struct S {}
            @available(iOS 26.0, tvOS 27.0, *)
            extension Example.S {
              public func f()
            }
            """
        )
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
        #expect(change.listOfChanges.contains("Added attribute `@available(iOS 26.0, tvOS 27.0, *)`"))
    }

    /// Mirrors `FoundationModels.SystemLanguageModel` (iOS 27.2 → 27.3): the extension header changes
    /// and a sibling extension of the same type exists. Members must be reported as modified, never removed.
    @Test func extensionHeaderChangeIsReportedOnMembers() throws {
        let changes = compare(
            """
            public final class Model {}
            @available(iOS 26.0, *)
            @available(watchOS, unavailable)
            @available(tvOS, unavailable)
            extension Example.Model {
              final public var isAvailable: Swift.Bool { get }
            }
            @available(iOS 27.0, *)
            extension Example.Model {
              public struct Executor {}
            }
            """,
            """
            public final class Model {}
            @available(iOS 27.0, *)
            extension Example.Model {
              public struct Executor {}
            }
            @available(iOS 26.0, tvOS 27.3, *)
            @available(watchOS, unavailable)
            extension Example.Model {
              final public var isAvailable: Swift.Bool { get }
            }
            """
        )
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
        #expect(change.parentPath == "Model")
        #expect(change.listOfChanges.contains("Removed attribute `@available(tvOS, unavailable)`"))
    }

    @Test func memberAvailabilityTakesPrecedencePerPlatform() {
        let attributes = AvailabilityInheritance.attributes(
            ["@available(iOS 26.0, tvOS 27.3, *)", "@MainActor"],
            inheriting: ["@available(iOS 26.0, macOS 26.0, tvOS 27.3, *)", "@available(watchOS, unavailable)", "@_spi(X)"]
        )
        #expect(attributes == [
            "@available(iOS 26.0, tvOS 27.3, *)",
            "@available(macOS 26.0, *)",
            "@available(watchOS, unavailable)",
            "@MainActor"
        ])
    }

    @Test func memberLongFormAvailabilityCoversPlatform() {
        let attributes = AvailabilityInheritance.attributes(
            ["@available(tvOS, unavailable)"],
            inheriting: ["@available(iOS 18.0, tvOS 18.0, *)", "@available(*, deprecated, message: \"a, b\")"]
        )
        #expect(attributes == [
            "@available(*, deprecated, message: \"a, b\")",
            "@available(iOS 18.0, *)",
            "@available(tvOS, unavailable)"
        ])
    }

    @Test func membersWithoutExtensionAttributesAreUnchanged() {
        #expect(AvailabilityInheritance.attributes(["@discardableResult"], inheriting: []) == ["@discardableResult"])
    }

    private func compare(_ old: String, _ new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
