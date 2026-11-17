//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

/// Extensions that can't be merged into their extended type (e.g. of types of other modules)
/// are combined into one extension per extended type and generic where clause.
struct ExtensionCombiningTests {

    private func changes(from old: String, to new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }

    @Test func mergingExtensionBlocksIsNotAChange() {
        let changes = changes(
            from: """
            extension Other.View {
              public func first()
            }
            extension Other.View {
              public func second()
            }
            """,
            to: """
            extension Other.View {
              public func first()
              public func second()
            }
            """
        )

        #expect(changes.isEmpty, "\(changes)")
    }

    @Test func splittingExtensionBlocksIsNotAChange() {
        let changes = changes(
            from: """
            @available(iOS 17.0, *)
            extension Other.View {
              public func first()
              public func second()
            }
            """,
            to: """
            @available(iOS 17.0, *)
            extension Other.View {
              public func second()
            }
            @available(iOS 17.0, *)
            extension Other.View {
              public func first()
            }
            """
        )

        #expect(changes.isEmpty, "\(changes)")
    }

    @Test func memberMovedToBlockWithOtherAvailabilityReportsAvailabilityChange() throws {
        let changes = changes(
            from: """
            @available(iOS 17.0, *)
            extension Other.View {
              public func first()
              public func second()
            }
            """,
            to: """
            @available(iOS 17.0, *)
            extension Other.View {
              public func first()
            }
            @available(iOS 18.0, *)
            extension Other.View {
              public func second()
            }
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.parentPath == "Other.View")
        #expect(change.listOfChanges == ["Availability changed: iOS 17.0 → 18.0"])
    }

    @Test func newMemberInNewBlockIsReportedAsMemberAddition() throws {
        let changes = changes(
            from: """
            extension Other.View {
              public func first()
            }
            """,
            to: """
            extension Other.View {
              public func first()
            }
            @available(iOS 18.0, *)
            extension Other.View {
              public func second()
            }
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.parentPath == "Other.View")
        #expect(change.changeType == .addition(description: "@available(iOS 18.0, *)\npublic func second() -> Swift.Void"))
    }

    @Test func extensionsWithDifferentWhereClausesAreNotCombined() throws {
        let root = SwiftInterfaceParser().parse(
            source: """
            extension Swift.Array where Element == Swift.Int {
              public func sum() -> Swift.Int
            }
            extension Swift.Array {
              public func first()
            }
            extension Swift.Array where Element == Swift.Int {
              public func average() -> Swift.Int
            }
            """,
            moduleName: "Example"
        )

        let extensions = root.children.compactMap { $0 as? SwiftInterfaceExtension }
        #expect(extensions.count == 2)
        let constrained = try #require(extensions.first { $0.genericWhereClauseDescription != nil })
        #expect(constrained.children.count == 2)
    }

    @Test func conformanceAvailabilityIsKeptAndRenderedAsExtension() throws {
        let root = SwiftInterfaceParser().parse(
            source: """
            @available(iOS 17.0, *)
            extension Other.View: Other.Hoverable {
              public func hover()
            }
            extension Other.View {
              public func tap()
            }
            """,
            moduleName: "Example"
        )

        let extensionElement = try #require(root.children.first as? SwiftInterfaceExtension)
        #expect(root.children.count == 1)
        #expect(extensionElement.recursiveDescription() == """
        extension Other.View {
          @available(iOS 17.0, *)
          public func hover() -> Swift.Void
          public func tap() -> Swift.Void
        }

        @available(iOS 17.0, *)
        extension Other.View: Other.Hoverable
        """)
    }

    @Test func conformanceAvailabilityChangeIsReported() throws {
        let changes = changes(
            from: """
            @available(iOS 17.0, *)
            extension Other.View: Other.Hoverable {}
            """,
            to: """
            @available(iOS 17.0, macOS 14.0, *)
            extension Other.View: Other.Hoverable {}
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.listOfChanges == ["Conformance `Other.Hoverable`: Availability added: macOS 14.0"])
    }

    @Test func extensionsWithOtherAttributesAreNotCombined() {
        let root = SwiftInterfaceParser().parse(
            source: """
            @_Concurrency.MainActor extension Other.View {
              public func first()
            }
            extension Other.View {
              public func second()
            }
            """,
            moduleName: "Example"
        )

        #expect(root.children.count == 2)
    }
}
