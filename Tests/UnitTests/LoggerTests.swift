//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
import XCTest

class LoggerTests: XCTestCase {
    
    func test_logger() async throws {
        
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
}
