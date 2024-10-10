//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
import XCTest

class PipelineTests: XCTestCase {
    
    func test_pipeline() async throws {
        
        let swiftInterfaceFile = SwiftInterfaceFile(
            name: "MODULE_NAME",
            oldFilePath: "old_file_path",
            newFilePath: "new_file_path"
        )
        
        let expectedChanges: [Change] = [.init(changeType: .addition(description: "addition"))]
        var expectedHandleLoadDataCalls = ["new_file_path", "old_file_path"]
        var expectedHandleParseSourceCalls: [(source: String, moduleName: String)] = [
            ("content_for_new_file_path", "MODULE_NAME"),
            ("content_for_old_file_path", "MODULE_NAME")
        ]
        var expectedHandleAnalyzeCalls: [(old: SwiftInterfaceParser.Root, new: SwiftInterfaceParser.Root)] = [
            (.init(moduleName: "MODULE_NAME", elements: []), .init(moduleName: "MODULE_NAME", elements: []))
        ]
        var expectedHandleLogCalls: [(message: String, subsystem: String)] = [
            ("🧑‍🔬 Analyzing MODULE_NAME", "SwiftInterfacePipeline")
        ]
        let expectedPipelineOutput: [String: [Change]] = ["MODULE_NAME": expectedChanges]
        
        // Mock Setup
        
        var fileHandler = MockFileHandler()
        fileHandler.handleLoadData = { path in
            let expectedInput = expectedHandleLoadDataCalls.removeFirst()
            XCTAssertEqual(path, expectedInput)
            return try XCTUnwrap(String("content_for_\(path)").data(using: .utf8))
        }
        
        var swiftInterfaceParser = MockSwiftInterfaceParser()
        swiftInterfaceParser.handleParseSource = { source, moduleName in
            let expectedInput = expectedHandleParseSourceCalls.removeFirst()
            XCTAssertEqual(expectedInput.source, source)
            XCTAssertEqual(expectedInput.moduleName, moduleName)
            return SwiftInterfaceParser.Root(moduleName: moduleName, elements: [])
        }
        
        var swiftInterfaceAnalyzer = MockSwiftInterfaceAnalyzer()
        swiftInterfaceAnalyzer.handleAnalyze = { old, new in
            let expectedInput = expectedHandleAnalyzeCalls.removeFirst()
            XCTAssertEqual(old.recursiveDescription(), expectedInput.old.recursiveDescription())
            XCTAssertEqual(new.recursiveDescription(), expectedInput.new.recursiveDescription())
            return expectedChanges
        }
        
        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            let expectedInput = expectedHandleLogCalls.removeFirst()
            XCTAssertEqual(message, expectedInput.message)
            XCTAssertEqual(subsystem, expectedInput.subsystem)
        }
        
        // Pipeline run
        
        let pipeline = SwiftInterfacePipeline(
            fileHandler: fileHandler,
            swiftInterfaceParser: swiftInterfaceParser,
            swiftInterfaceAnalyzer: swiftInterfaceAnalyzer,
            logger: logger
        )
        
        let pipelineOutput = try await pipeline.run(with: [swiftInterfaceFile])
        
        // Validation
        
        XCTAssertEqual(pipelineOutput, expectedPipelineOutput)
        XCTAssertTrue(expectedHandleLoadDataCalls.isEmpty)
        XCTAssertTrue(expectedHandleParseSourceCalls.isEmpty)
        XCTAssertTrue(expectedHandleLogCalls.isEmpty)
        XCTAssertTrue(expectedHandleAnalyzeCalls.isEmpty)
    }
}
