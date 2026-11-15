//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

/// Every clause of an `#if` is parsed and its declarations are tagged with the clause's condition
/// (see `ConditionalCompilation`)
struct ConditionalCompilationTests {

    private func parse(_ source: String) -> SwiftInterfaceParser.Root {
        // swiftlint:disable:next force_cast
        SwiftInterfaceParser().parse(source: source, moduleName: "Example") as! SwiftInterfaceParser.Root
    }

    private func changes(from old: String, to new: String) -> [Change] {
        SwiftInterfaceAnalyzer().analyze(old: parse(old), new: parse(new))
    }

    // MARK: - Parsing

    @Test func everyClauseIsTaggedWithItsCondition() throws {
        let root = parse("""
        #if compiler(>=5.3) && $TildeSendable
        public struct Shape: Example.Provider, ~Swift.Sendable {
          public var size: Swift.Int
        }
        #else
        public struct Shape: Example.Provider {
          public var size: Swift.Int
        }
        #endif
        """)

        let shapes = root.children.compactMap { $0 as? SwiftInterfaceStruct }
        #expect(shapes.count == 2)
        #expect(shapes.map(\.conditions) == [
            ["compiler(>=5.3) && $TildeSendable"],
            ["!(compiler(>=5.3) && $TildeSendable)"]
        ])
        #expect(shapes.first?.attributes == ["#if compiler(>=5.3) && $TildeSendable"])
        // Members inherit the conditions of their type
        let size = try #require(shapes.last?.children.first)
        #expect(size.conditions.isEmpty)
        #expect(size.allConditions == ["!(compiler(>=5.3) && $TildeSendable)"])
    }

    @Test func membersInsideIfAreTagged() throws {
        let root = parse("""
        public struct Buffer {
          #if compiler(>=5.3) && $Lifetimes
          public var span: Swift.Span<Swift.UInt8> {
            @lifetime(borrow self) get
          }
          #else
          public var span: Swift.Span<Swift.UInt8> {
            @_lifetime(borrow self) get
          }
          #endif
          public var count: Swift.Int
        }
        """)

        let buffer = try #require(root.children.first)
        #expect(buffer.conditions.isEmpty)
        #expect(buffer.children.map(\.conditions) == [
            ["compiler(>=5.3) && $Lifetimes"],
            ["!(compiler(>=5.3) && $Lifetimes)"],
            []
        ])
    }

    @Test func elseifConditionsIncludeThePreviousClauses() {
        let root = parse("""
        #if $Embedded
        public func embedded()
        #elseif compiler(>=6.0)
        public func current()
        #else
        public func legacy()
        #endif
        """)

        #expect(root.children.map(\.conditions) == [
            ["$Embedded"],
            ["!$Embedded && compiler(>=6.0)"],
            ["!$Embedded && !compiler(>=6.0)"]
        ])
    }

    @Test func nestedIfsAreCombined() {
        let root = parse("""
        #if os(macOS)
        #if !$Embedded
        public func mac()
        #endif
        #endif
        """)

        #expect(root.children.map(\.conditions) == [["os(macOS)", "!$Embedded"]])
    }

    @Test func attributesInsideIfAreKeptPerClause() throws {
        let root = parse("""
        #if compiler(>=5.3) && $NonexhaustiveAttribute
        @nonexhaustive
        #else
        @frozen
        #endif
        public enum Kind {
          case a
        }
        """)

        let kind = try #require(root.children.first as? SwiftInterfaceEnum)
        #expect(kind.attributes == [
            "#if compiler(>=5.3) && $NonexhaustiveAttribute @nonexhaustive #endif",
            "#if !(compiler(>=5.3) && $NonexhaustiveAttribute) @frozen #endif"
        ])
        #expect(kind.conditions.isEmpty)
    }

    @Test func extensionIsMergedIntoTheVariantWithTheSameConditions() throws {
        let root = parse("""
        #if $TildeSendable
        public struct Shape: ~Swift.Sendable {}
        #else
        public struct Shape {}
        #endif
        #if $TildeSendable
        extension Example.Shape: Example.Provider {
          public func draw()
        }
        #else
        extension Example.Shape: Example.Provider {
          public func legacyDraw()
        }
        #endif
        """)

        let shapes = root.children.compactMap { $0 as? SwiftInterfaceStruct }
        #expect(shapes.count == 2)
        #expect(shapes.map { $0.children.map(\.consolidatableName) } == [["draw"], ["legacyDraw"]])
        #expect(shapes.map(\.inheritance) == [["~Swift.Sendable", "Example.Provider"], ["Example.Provider"]])
        #expect(shapes.flatMap(\.children).allSatisfy { $0.conditions.isEmpty })
    }

    @Test func conditionsOfAnExtensionAreKeptWhenMerged() throws {
        let root = parse("""
        public struct Shape {}
        #if $LifetimeDependence
        @available(iOS 27.0, *)
        extension Example.Shape: Example.Provider {
          public func borrowed()
        }
        #endif
        """)

        let shape = try #require(root.children.first as? SwiftInterfaceStruct)
        #expect(shape.children.map(\.conditions) == [["$LifetimeDependence"]])
        #expect(shape.children.compactMap { ($0 as? SwiftInterfaceFunction)?.attributes } == [["#if $LifetimeDependence", "@available(iOS 27.0, *)"]])
        #expect(shape.inheritance == ["Example.Provider /* #if $LifetimeDependence\n@available(iOS 27.0, *) */"])
    }

    @Test func macrosAreTagged() {
        let root = parse("""
        #if compiler(>=5.3) && $Macros
        @freestanding(expression) public macro stringify<T>(_ value: T) -> (T, Swift.String) = #externalMacro(module: "ExampleMacros", type: "StringifyMacro")
        #endif
        """)

        #expect(root.children.map(\.conditions) == [["compiler(>=5.3) && $Macros"]])
    }

    // MARK: - Changes

    @Test func unchangedClausesDoNotProduceChanges() {
        let changes = changes(
            from: """
            #if compiler(>=5.3) && $TildeSendable
            public struct Shape: ~Swift.Sendable {}
            #else
            public struct Shape {}
            #endif
            """,
            to: """
            #if compiler(>=5.3) && $TildeSendable
            public struct Shape: ~Swift.Sendable {}
            #else
            public struct Shape {}
            #endif
            public func added()
            """
        )

        #expect(changes.count == 1)
        #expect(changes.first?.conditions == [])
    }

    @Test func variantsAreComparedWithTheSameVariant() throws {
        let changes = changes(
            from: """
            public struct Buffer {
              #if $Lifetimes
              public var span: Swift.Span<Swift.UInt8> {
                @lifetime(borrow self) get
              }
              #else
              public var span: Swift.Span<Swift.UInt8> {
                @_lifetime(borrow self) get
              }
              #endif
            }
            """,
            to: """
            public struct Buffer {
              #if $Lifetimes
              public var span: Swift.Span<Swift.UInt16> {
                @lifetime(borrow self) get
              }
              #else
              public var span: Swift.Span<Swift.UInt8> {
                @_lifetime(borrow self) get
              }
              #endif
            }
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.conditions == ["$Lifetimes"])
        #expect(change.listOfChanges == ["Modified type from `Swift.Span<Swift.UInt8>` to `Swift.Span<Swift.UInt16>`"])
    }

    @Test func changeOnlyInFallbackClauseIsReported() throws {
        let changes = changes(
            from: """
            #if $TildeSendable
            public struct Shape: ~Swift.Sendable {
              public func draw()
            }
            #else
            public struct Shape {
              public func draw()
            }
            #endif
            """,
            to: """
            #if $TildeSendable
            public struct Shape: ~Swift.Sendable {
              public func draw()
            }
            #else
            public struct Shape {
              public func draw()
              public func legacyDraw()
            }
            #endif
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.changeType.isAddition)
        #expect(change.conditions == ["!$TildeSendable"])
        #expect(change.parentPath == "Shape")
    }

    @Test func declarationMovingIntoGatedClauseIsAConditionChange() throws {
        let changes = changes(
            from: """
            public func borrowed() -> Swift.Int
            """,
            to: """
            #if $LifetimeDependence
            public func borrowed() -> Swift.Int
            #endif
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.changeType.isModification)
        #expect(change.listOfChanges == ["Added condition `#if $LifetimeDependence`"])
        #expect(change.conditions == ["$LifetimeDependence"])
    }

    @Test func typeSplitIntoVariantsReportsTheNewVariant() throws {
        let changes = changes(
            from: """
            public struct Shape {}
            """,
            to: """
            #if compiler(>=5.3) && $TildeSendable
            public struct Shape: ~Swift.Sendable {}
            #else
            public struct Shape {}
            #endif
            """
        )

        // The `#else` variant is the former declaration (now behind a condition), the `#if` variant is new
        #expect(changes.count == 2, "\(changes)")
        let addition = try #require(changes.first { $0.changeType.isAddition })
        #expect(addition.conditions == ["compiler(>=5.3) && $TildeSendable"])
        let modification = try #require(changes.first { $0.changeType.isModification })
        #expect(modification.listOfChanges == ["Added condition `#if !(compiler(>=5.3) && $TildeSendable)`"])
    }

    @Test func conditionalAttributeChangeIsReported() throws {
        let changes = changes(
            from: """
            public enum Kind {
              case a
            }
            """,
            to: """
            #if $NonexhaustiveAttribute
            @nonexhaustive
            #endif
            public enum Kind {
              case a
            }
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.listOfChanges == ["Added attribute `@nonexhaustive` (`#if $NonexhaustiveAttribute`)"])
        #expect(change.conditions.isEmpty)
    }

    // MARK: - Rendering

    @Test func additionRendersConditionsAsBlocks() throws {
        let changes = changes(
            from: "",
            to: """
            #if compiler(>=5.3) && $TildeSendable
            public struct Shape: ~Swift.Sendable {
              #if !$Embedded
              public func describe() -> Swift.String
              public func area() -> Swift.Double
              #endif
              public var size: Swift.Int
            }
            #endif
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.changeType == .addition(description: """
        #if compiler(>=5.3) && $TildeSendable
        public struct Shape: ~Swift.Sendable {
          public var size: Swift.Int
          #if !$Embedded
          public func area() -> Swift.Double
          public func describe() -> Swift.String
          #endif
        }
        #endif
        """))
    }

    @Test func memberChangeIsWrappedInTheConditionsOfItsType() throws {
        let changes = changes(
            from: """
            #if $TildeSendable
            public struct Canvas: ~Swift.Sendable {}
            #else
            public struct Canvas {}
            #endif
            """,
            to: """
            #if $TildeSendable
            public struct Canvas: ~Swift.Sendable {}
            #else
            public struct Canvas {
              public func legacyDraw()
            }
            #endif
            """
        )

        let change = try #require(changes.first)
        #expect(changes.count == 1, "\(changes)")
        #expect(change.changeType == .addition(description: """
        #if !$TildeSendable
        public func legacyDraw() -> Swift.Void
        #endif
        """))
    }

    @Test func gateChangeShowsTheConditionOnlyOnTheNewSide() throws {
        let changes = changes(
            from: "public func borrowed() -> Swift.Int",
            to: """
            #if $LifetimeDependence
            public func borrowed() -> Swift.Int
            #endif
            """
        )

        let change = try #require(changes.first)
        #expect(change.changeType == .modification(
            oldDescription: "public func borrowed() -> Swift.Int",
            newDescription: "#if $LifetimeDependence\npublic func borrowed() -> Swift.Int\n#endif"
        ))
    }

    @Test func conditionalConformanceIsRenderedAsWrappedExtension() throws {
        let changes = changes(
            from: "",
            to: """
            public struct Shape {}
            #if $LifetimeDependence
            extension Example.Shape: Example.Provider {}
            #endif
            """
        )

        let change = try #require(changes.first)
        #expect(change.changeType == .addition(description: """
        public struct Shape

        #if $LifetimeDependence
        extension Shape: Example.Provider
        #endif
        """))
    }

    @Test func conditionalAttributeIsRenderedAsDeclared() throws {
        let changes = changes(
            from: "",
            to: """
            #if compiler(>=5.3) && $NonexhaustiveAttribute
            @nonexhaustive
            #endif
            public enum Kind {}
            """
        )

        let change = try #require(changes.first)
        #expect(change.changeType == .addition(description: """
        #if compiler(>=5.3) && $NonexhaustiveAttribute
        @nonexhaustive
        #endif
        public enum Kind
        """))
    }
}
