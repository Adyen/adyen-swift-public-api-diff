//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADCore
@testable import PADSwiftInterfaceDiff
import Testing

@Test func pipeline() async throws {
    try await runPipeline(apiScope: nil, expectedApiScope: .all)
}

@Test(arguments: [APIScope.all, .package, .public])
func pipelinePassesAPIScopeToParser(apiScope: APIScope) async throws {
    try await runPipeline(apiScope: apiScope, expectedApiScope: apiScope)
}

/// - Parameters:
///   - apiScope: The scope passed to the pipeline. `nil` uses the pipeline's default
///   - expectedApiScope: The scope the parser is expected to receive
private func runPipeline(apiScope: APIScope?, expectedApiScope: APIScope) async throws {

        let swiftInterfaceFile = SwiftInterfaceFile(
            name: "MODULE_NAME",
            oldFilePath: "old_file_path",
            newFilePath: "new_file_path"
        )

        let expectedChanges: [Change] = [.init(changeType: .addition(description: "addition"))]
        var expectedHandleLoadDataCalls = ["new_file_path", "old_file_path"]
        var expectedHandleParseSourceCalls: [(source: String, moduleName: String, apiScope: APIScope)] = [
            ("content_for_new_file_path", "MODULE_NAME", expectedApiScope),
            ("content_for_old_file_path", "MODULE_NAME", expectedApiScope)
        ]
        var expectedHandleAnalyzeCalls: [(old: SwiftInterfaceParser.Root, new: SwiftInterfaceParser.Root)] = [
            (.init(moduleName: "MODULE_NAME", elements: []), .init(moduleName: "MODULE_NAME", elements: []))
        ]
        var expectedHandleLogCalls: [(message: String, subsystem: String)] = [
            ("🧑‍🔬 Analyzing MODULE_NAME", "SwiftInterfaceDiff")
        ]
        let expectedPipelineOutput: [String: [Change]] = ["MODULE_NAME": expectedChanges]

        // Mock Setup

        var fileHandler = MockFileHandler()
        fileHandler.handleLoadData = { path in
            let expectedInput = expectedHandleLoadDataCalls.removeFirst()
            #expect(path == expectedInput)
            return try #require(String("content_for_\(path)").data(using: .utf8))
        }

        var swiftInterfaceParser = MockSwiftInterfaceParser()
        swiftInterfaceParser.handleParseSource = { source, moduleName, apiScope in
            let expectedInput = expectedHandleParseSourceCalls.removeFirst()
            #expect(expectedInput.source == source)
            #expect(expectedInput.moduleName == moduleName)
            #expect(expectedInput.apiScope == apiScope)
            return SwiftInterfaceParser.Root(moduleName: moduleName, elements: [])
        }

        var swiftInterfaceAnalyzer = MockSwiftInterfaceAnalyzer()
        swiftInterfaceAnalyzer.handleAnalyze = { old, new in
            let expectedInput = expectedHandleAnalyzeCalls.removeFirst()
            #expect(old.recursiveDescription() == expectedInput.old.recursiveDescription())
            #expect(new.recursiveDescription() == expectedInput.new.recursiveDescription())
            return expectedChanges
        }

        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            let expectedInput = expectedHandleLogCalls.removeFirst()
            #expect(message == expectedInput.message)
            #expect(subsystem == expectedInput.subsystem)
        }

        // Pipeline run

        let pipeline = if let apiScope {
            SwiftInterfaceDiff(
                fileHandler: fileHandler,
                swiftInterfaceParser: swiftInterfaceParser,
                swiftInterfaceAnalyzer: swiftInterfaceAnalyzer,
                apiScope: apiScope,
                logger: logger
            )
        } else {
            SwiftInterfaceDiff(
                fileHandler: fileHandler,
                swiftInterfaceParser: swiftInterfaceParser,
                swiftInterfaceAnalyzer: swiftInterfaceAnalyzer,
                logger: logger
            )
        }

        let pipelineOutput = try await pipeline.run(with: [swiftInterfaceFile])

        // Validation

        #expect(pipelineOutput == expectedPipelineOutput)
        #expect(expectedHandleLoadDataCalls.isEmpty)
        #expect(expectedHandleParseSourceCalls.isEmpty)
        #expect(expectedHandleLogCalls.isEmpty)
        #expect(expectedHandleAnalyzeCalls.isEmpty)
    }
