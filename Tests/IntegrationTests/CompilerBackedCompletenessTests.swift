//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

/// Checks emitted interfaces against the compiler, rather than handwritten expectations alone.
@Suite(.serialized)
struct CompilerBackedCompletenessTests {

    struct Scenario: Sendable {
        let name: String
        let old: String
        let new: String
        let client: String
        let expectedReportFragment: String
    }

    static let scenarios: [Scenario] = [
        .init(
            name: "protocol default implementation",
            old: "public protocol P { func f() }\nextension P { public func f() {} }",
            new: "public protocol P { func f() }",
            client: "struct C: P {}",
            expectedReportFragment: "extension"
        ),
        .init(
            name: "variadic parameter",
            old: "public func f(_ values: Int...) {}",
            new: "public func f(_ values: Int) {}",
            client: "f(1, 2)",
            expectedReportFragment: "Swift.Int..."
        ),
        .init(
            name: "operator declaration",
            old: "prefix operator ~~>\npublic prefix func ~~> (_ value: Int) -> Int { value }",
            new: "",
            client: "_ = ~~>1",
            expectedReportFragment: "prefix operator ~~>"
        ),
        .init(
            name: "precedence group",
            old: """
            precedencegroup P { associativity: left }
            infix operator <~>: P
            public func <~> (_ lhs: Int, _ rhs: Int) -> Int { lhs + rhs }
            """,
            new: """
            precedencegroup P { associativity: none }
            infix operator <~>: P
            public func <~> (_ lhs: Int, _ rhs: Int) -> Int { lhs + rhs }
            """,
            client: "print(1 <~> 2 <~> 3)",
            expectedReportFragment: "Modified associativity"
        ),
        .init(
            name: "re-exported import",
            old: "@_exported import Foundation",
            new: "import Foundation",
            client: "_ = Date()",
            expectedReportFragment: "Removed attribute `@_exported`"
        ),
        .init(
            name: "initializer inheritance",
            old: """
            open class Base {
                public init() {}
                public convenience init(value: Int) { self.init() }
            }
            open class Child: Base {}
            """,
            new: """
            open class Base {
                public init() {}
                public convenience init(value: Int) { self.init() }
            }
            open class Child: Base { public init(other: Int) { super.init() } }
            """,
            client: "_ = Child(value: 1)",
            expectedReportFragment: "Removed attribute `@_inheritsConvenienceInitializers`"
        )
    ]

    @Test(arguments: scenarios)
    func compilerConfirmedClientBreakIsReported(_ scenario: Scenario) async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sdk = try run(["--sdk", "macosx", "--show-sdk-path"])
        try #require(sdk.status == 0, Comment(rawValue: sdk.output))
        let sdkPath = sdk.output.trimmingCharacters(in: .whitespacesAndNewlines)
        let client = directory.appendingPathComponent("Client.swift")
        try ("import Example\n" + scenario.client).write(to: client, atomically: true, encoding: .utf8)

        var interfaces = [String]()
        for (version, source) in [("old", scenario.old), ("new", scenario.new)] {
            let moduleDirectory = directory.appendingPathComponent(version)
            try FileManager.default.createDirectory(at: moduleDirectory, withIntermediateDirectories: true)
            let librarySource = moduleDirectory.appendingPathComponent("Library.swift")
            try source.write(to: librarySource, atomically: true, encoding: .utf8)
            let interface = moduleDirectory.appendingPathComponent("Example.swiftinterface")
            let module = moduleDirectory.appendingPathComponent("Example.swiftmodule")
            let build = try run([
                "swiftc", "-sdk", sdkPath, "-swift-version", "5", "-parse-as-library", "-enable-library-evolution",
                "-emit-module", "-module-name", "Example",
                "-emit-module-path", module.path,
                "-emit-module-interface-path", interface.path, librarySource.path
            ])
            try #require(build.status == 0, Comment(rawValue: "\(scenario.name), \(version): \(build.output)"))
            // Force the client to import the text interface, not the binary module.
            try FileManager.default.removeItem(at: module)
            let typecheck = try run([
                "swiftc", "-sdk", sdkPath, "-typecheck", "-I", moduleDirectory.path,
                "-module-cache-path", moduleDirectory.appendingPathComponent("cache").path, client.path
            ])
            if version == "old" {
                try #require(typecheck.status == 0, Comment(rawValue: typecheck.output))
            } else {
                #expect(typecheck.status != 0, Comment(rawValue: "\(scenario.name): client must no longer compile"))
                #expect(!typecheck.output.contains("failed to build module"), Comment(rawValue: typecheck.output))
            }
            interfaces.append(interface.path)
        }

        let report = try await SwiftInterfaceDiff().run(with: [
            SwiftInterfaceFile(name: "Example", oldFilePath: interfaces[0], newFilePath: interfaces[1])
        ])
        let changes = try #require(report["Example"])
        let descriptions = changes.flatMap { change -> [String] in
            switch change.changeType {
            case let .addition(description), let .removal(description):
                [description] + change.listOfChanges
            case let .modification(oldDescription, newDescription):
                [oldDescription, newDescription] + change.listOfChanges
            }
        }
        #expect(descriptions.contains { $0.contains(scenario.expectedReportFragment) }, Comment(rawValue: scenario.name))
    }

    private func run(_ arguments: [String]) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
