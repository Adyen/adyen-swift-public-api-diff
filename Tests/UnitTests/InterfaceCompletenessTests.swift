//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct InterfaceCompletenessTests {

    @Test(arguments: [
        "public func f(_ values: Swift.Int)",
        "public struct S { public init(_ values: Swift.Int) }",
        "public struct S { public subscript(_ values: Swift.Int) -> Swift.Int { get } }",
        "public macro m(_ values: Swift.Int) = #externalMacro(module: \"M\", type: \"M\")"
    ])
    func variadicParameterChangeIsReported(_ source: String) throws {
        let changes = compare(source, source.replacingOccurrences(of: "values: Swift.Int", with: "values: Swift.Int..."))
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isModification)
        #expect(change.listOfChanges == [
            "Modified parameter `values`: Changed type from `Swift.Int` to `Swift.Int...`"
        ])
    }

    @Test(arguments: [
        "func f()",
        "var value: Swift.Int { get }",
        "init()"
    ])
    func removalOfProtocolDefaultImplementationIsReported(_ requirement: String) throws {
        let declaration = "public protocol P { \(requirement) }"
        let implementation = "extension Example.P { public \(requirement) }"
        let changes = compare(declaration + "\n" + implementation, declaration)
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.changeType.isRemoval)
        guard case let .removal(description) = change.changeType else {
            Issue.record("Expected a removed default implementation")
            return
        }
        #expect(description.contains("extension"))
        #expect(description.contains(requirement))
    }

    @Test func operatorPrecedenceChangeIsReported() throws {
        let changes = compare("infix operator <~>: AdditionPrecedence", "infix operator <~>: MultiplicationPrecedence")
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.listOfChanges == ["Modified precedence group from `AdditionPrecedence` to `MultiplicationPrecedence`"])
    }

    @Test(arguments: [
        ("associativity: left", "associativity: none", "Modified associativity from `left` to `none`"),
        ("assignment: false", "assignment: true", "Modified assignment from `false` to `true`"),
        ("higherThan: A", "higherThan: B", "Modified higherThan from `A` to `B`"),
        ("lowerThan: A", "lowerThan: B", "Modified lowerThan from `A` to `B`")
    ])
    func precedenceGroupChangeIsReported(_ scenario: (String, String, String)) throws {
        let changes = compare("precedencegroup P { \(scenario.0) }", "precedencegroup P { \(scenario.1) }")
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.listOfChanges == [scenario.2])
    }

    @Test func removalOfReexportIsReported() throws {
        let changes = compare("@_exported import Foundation", "import Foundation")
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.listOfChanges == ["Removed attribute `@_exported`"])
    }

    @Test(arguments: ["@_inheritsConvenienceInitializers", "@_hasMissingDesignatedInitializers"])
    func initializerInheritanceMetadataChangeIsReported(_ attribute: String) throws {
        let changes = compare("\(attribute) open class C {}", "open class C {}")
        let change = try #require(changes.first)
        #expect(changes.count == 1)
        #expect(change.listOfChanges == ["Removed attribute `\(attribute)`"])
    }

    @Test func unrelatedInitializersAreReportedAsRemovalAndAddition() {
        let changes = compare(
            "public class C { public init() }",
            "public class C { public init(other: Swift.Int) }"
        )
        #expect(changes.count == 2)
        #expect(changes.filter { $0.changeType.isRemoval }.count == 1)
        #expect(changes.filter { $0.changeType.isAddition }.count == 1)
    }

    private func compare(_ old: String, _ new: String) -> [Change] {
        let parser = SwiftInterfaceParser()
        return SwiftInterfaceAnalyzer().analyze(
            old: parser.parse(source: old, moduleName: "Example"),
            new: parser.parse(source: new, moduleName: "Example")
        )
    }
}
