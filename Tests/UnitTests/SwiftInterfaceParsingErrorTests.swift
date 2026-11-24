//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
@testable import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

struct SwiftInterfaceParsingErrorTests {

    @Test func truncatedInterfaceThrows() throws {
        let source = """
        public struct S {
          public func f()
        """

        let error = try #require(throws: SwiftInterfaceParsingError.self) {
            try SwiftInterfaceParser().parse(source: source, moduleName: "Example")
        }
        #expect(error.filePath == nil)
        #expect(error.diagnostics.count == 1)
        #expect(error.diagnostics.first?.hasPrefix("2:18: ") == true)
    }

    @Test func unexpectedTokensThrow() throws {
        let source = """
        public struct S {}
        @@@ garbage ###
        """

        let error = try #require(throws: SwiftInterfaceParsingError.self) {
            try SwiftInterfaceParser().parse(source: source, moduleName: "Example")
        }
        #expect(error.diagnostics.contains { $0.hasPrefix("2:") })
    }

    @Test func validInterfaceDoesNotThrow() throws {
        let source = """
        // swift-interface-format-version: 1.0
        import Swift
        #if compiler(>=5.3) && $Macros
        @freestanding(expression) public macro m() = #externalMacro(module: "M", type: "M")
        #endif
        public struct S {
          public func f()
        }
        """

        _ = try SwiftInterfaceParser().parse(source: source, moduleName: "Example")
    }

    @Test func unknownAttributeArgumentsAreTolerated() throws {
        let source = """
        @available(iOS, futureKeyword: 1)
        public func f()
        """

        _ = try SwiftInterfaceParser().parse(source: source, moduleName: "Example")
    }

    @Test func pipelineReportsThePathOfTheInvalidFile() async throws {
        var fileHandler = MockFileHandler()
        fileHandler.handleLoadData = { path in
            let source = path == "new.swiftinterface" ? "public struct S {" : "public struct S {}"
            return try #require(source.data(using: .utf8))
        }

        let pipeline = SwiftInterfaceDiff(
            fileHandler: fileHandler,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer()
        )

        let error = await #expect(throws: SwiftInterfaceParsingError.self) {
            try await pipeline.run(with: [.init(name: "Example", oldFilePath: "old.swiftinterface", newFilePath: "new.swiftinterface")])
        }
        #expect(error?.filePath == "new.swiftinterface")
        #expect(error?.errorDescription?.contains("`new.swiftinterface`") == true)
    }

    @Test func descriptionListsTheFirstDiagnostics() {
        let error = SwiftInterfaceParsingError(
            filePath: "file.swiftinterface",
            diagnostics: (1...12).map { "\($0):1: error \($0)" }
        )

        let lines = error.errorDescription?.components(separatedBy: "\n") ?? []
        #expect(lines.first == "Could not parse the interface file `file.swiftinterface`: found 12 syntax error(s)")
        #expect(lines.count == 12)
        #expect(lines[1] == "- 1:1: error 1")
        #expect(lines[10] == "- 10:1: error 10")
        #expect(lines.last == "- ... and 2 more")
    }
}
