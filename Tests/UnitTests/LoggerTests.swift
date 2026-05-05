//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADLogging
import Testing

@Test func logLevels() async throws {

    var logger = MockLogger()

    // .quiet

    logger.handleLog = { _, _ in Issue.record(".handleLog should not be called") }
    logger.handleDebug = { _, _ in Issue.record(".handleDebug should not be called") }
    logger.withLogLevel(.quiet).log("log", from: "quiet")
    logger.withLogLevel(.quiet).debug("debug", from: "quiet")

    // .default

    logger.handleLog = { message, subsystem in
        #expect(message == "log")
        #expect(subsystem == "default")
    }
    logger.handleDebug = { _, _ in Issue.record(".handleDebug should not be called") }
    logger.withLogLevel(.default).log("log", from: "default")
    logger.withLogLevel(.default).debug("debug", from: "default")

    // .debug

    logger.handleLog = { message, subsystem in
        #expect(message == "log")
        #expect(subsystem == "debug")
    }
    logger.handleDebug = { message, subsystem in
        #expect(message == "debug")
        #expect(subsystem == "debug")
    }
    logger.withLogLevel(.debug).log("log", from: "debug")
    logger.withLogLevel(.debug).debug("debug", from: "debug")
}

@Test func logFileLogger() async throws {

    let outputFilePath = "output_file_path"

    var removeCallCount = 0

    var expectedHandleCreateFileCalls = [
        "🪵 [test] log\n",
        "🪵 [test] log\n\n🐞 [test] debug\n"
    ]

    var fileHandler = MockFileHandler()
    fileHandler.handleRemoveItem = { path in
        #expect(path == outputFilePath)
        removeCallCount += 1
    }
    fileHandler.handleCreateFile = { path, data in
        #expect(path == outputFilePath)
        let expectedInput = expectedHandleCreateFileCalls.removeFirst()
        #expect(String(data: data, encoding: .utf8) == expectedInput)
        return true
    }

    let logFileLogger = LogFileLogger(fileHandler: fileHandler, outputFilePath: outputFilePath)

    logFileLogger.log("log", from: "test")
    // Small sleep because the file manager calls are done on a detached Task and we want to guarantee the order
    try await Task.sleep(for: .milliseconds(10))
    logFileLogger.debug("debug", from: "test")

    try await Task.sleep(for: .milliseconds(50))
    #expect(removeCallCount == 2)
    #expect(expectedHandleCreateFileCalls.isEmpty)
}
