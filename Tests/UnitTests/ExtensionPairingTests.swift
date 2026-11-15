//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct ExtensionPairingTests {

    /// Mirrors `FoundationModels` (iOS 27.2 → 27.3): extensions of a type outside the module stay standalone.
    /// When their availability changes, each must be compared with the extension declaring the same conformance.
    @Test func standaloneExtensionsWithChangedHeaderArePairedByConformance() {
        let changes = compare(
            """
            @available(iOS 27.0, *)
            @available(tvOS, unavailable)
            extension Swift.Never: Example.DynamicInstructions {}
            @available(iOS 27.0, *)
            @available(tvOS, unavailable)
            extension Swift.Never: Example.DynamicProfile {}
            @available(iOS 26.0, *)
            @available(tvOS, unavailable)
            extension Swift.Never: Example.Generable {}
            """,
            """
            @available(iOS 27.0, tvOS 27.0, *)
            extension Swift.Never: Example.DynamicInstructions {}
            @available(iOS 27.0, tvOS 27.0, *)
            extension Swift.Never: Example.DynamicProfile {}
            @available(iOS 26.0, tvOS 27.0, *)
            extension Swift.Never: Example.Generable {}
            """
        )
        #expect(changes.count == 3)
        #expect(changes.allSatisfy { $0.changeType.isModification })
        #expect(changes.flatMap(\.listOfChanges).allSatisfy { !$0.contains("inheritance") })
    }

    /// Extensions with members and the same conformance prefer the candidate with the most matching members
    @Test func standaloneExtensionsWithChangedHeaderArePairedByMembers() {
        let changes = compare(
            """
            @available(iOS 26.0, *)
            extension Swift.Never {
              public func first()
            }
            @available(iOS 26.0, *)
            extension Swift.Never {
              public func second()
            }
            """,
            """
            @available(iOS 26.0, *)
            extension Swift.Never {
              public func first()
            }
            @available(iOS 26.0, tvOS 27.0, *)
            extension Swift.Never {
              public func second()
            }
            """
        )
        #expect(changes.count == 1)
        #expect(changes.first?.changeType.isModification == true)
    }

    private func compare(_ old: String, _ new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
