//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADLogging
import XCTest

class LoggerTests: XCTestCase {

    func test_logLevels() async throws {

        var logger = MockLogger()

        // .quiet

        logger.handleLog = { _, _ in XCTFail(".handleLog should not be called") }
        logger.handleDebug = { _, _ in XCTFail(".handleDebug should not be called") }
        logger.withLogLevel(.quiet).log("log", from: "quiet")
        logger.withLogLevel(.quiet).debug("debug", from: "quiet")

        // .default

        logger.handleLog = { message, subsystem in
            XCTAssertEqual(message, "log")
            XCTAssertEqual(subsystem, "default")
        }
        logger.handleDebug = { _, _ in XCTFail(".handleDebug should not be called") }
        logger.withLogLevel(.default).log("log", from: "default")
        logger.withLogLevel(.default).debug("debug", from: "default")

        // .debug

        logger.handleLog = { message, subsystem in
            XCTAssertEqual(message, "log")
            XCTAssertEqual(subsystem, "debug")
        }
        logger.handleDebug = { message, subsystem in
            XCTAssertEqual(message, "debug")
            XCTAssertEqual(subsystem, "debug")
        }
        logger.withLogLevel(.debug).log("log", from: "debug")
        logger.withLogLevel(.debug).debug("debug", from: "debug")
    }

    func test_logFileLogger() async throws {

        let outputFilePath = "output_file_path"

        let removeExpectation = expectation(description: "remove was called twice")
        removeExpectation.expectedFulfillmentCount = 2

        var expectedHandleCreateFileCalls = [
            "🪵 [test] log\n",
            "🪵 [test] log\n\n🐞 [test] debug\n"
        ]

        var fileHandler = MockFileHandler()
        fileHandler.handleRemoveItem = { path in
            XCTAssertEqual(path, outputFilePath)
            removeExpectation.fulfill()
        }
        fileHandler.handleCreateFile = { path, data in
            XCTAssertEqual(path, outputFilePath)
            let expectedInput = expectedHandleCreateFileCalls.removeFirst()
            XCTAssertEqual(String(data: data, encoding: .utf8), expectedInput)
            return true
        }

        let logFileLogger = LogFileLogger(fileHandler: fileHandler, outputFilePath: outputFilePath)

        logFileLogger.log("log", from: "test")
        // Small sleep because the file manager calls are done on a detached Task and we want to guarantee the order
        try await Task.sleep(for: .milliseconds(10))
        logFileLogger.debug("debug", from: "test")

        await fulfillment(of: [removeExpectation])
        XCTAssertTrue(expectedHandleCreateFileCalls.isEmpty)
    }
}
