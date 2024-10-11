//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import XCTest

class XcodeToolsTests: XCTestCase {
    
    func test_archive_swiftPackage() async throws {
        
        let projectDirectoryPath = "PROJECT_DIRECTORY_PATH"
        let scheme = "SCHEME"
        
        try await testArchiving(
            projectDirectoryPath: projectDirectoryPath,
            scheme: scheme,
            projectType: .swiftPackage
        )
    }
    
    func test_archive_xcodeProject() async throws {
        
        let projectDirectoryPath = "PROJECT_DIRECTORY_PATH"
        let scheme = "SCHEME"
        
        try await testArchiving(
            projectDirectoryPath: projectDirectoryPath,
            scheme: scheme,
            projectType: .xcodeProject(scheme: scheme)
        )
    }
}

private extension XcodeToolsTests {
    
    func testArchiving(
        projectDirectoryPath: String,
        scheme: String,
        projectType: PADProjectType
    ) async throws {
        
        let archiveResult = "ARCHIVE_RESULT"
        let expectedDerivedDataPath = "\(projectDirectoryPath)/.build"
        var expectedHandleExecuteCalls: [String] = {
            switch projectType {
            case .swiftPackage:
                ["cd \(projectDirectoryPath); xcodebuild clean build -scheme \"\(scheme)\" -destination \"generic/platform=iOS\" -derivedDataPath .build -sdk `xcrun --sdk iphonesimulator --show-sdk-path` BUILD_LIBRARY_FOR_DISTRIBUTION=YES -skipPackagePluginValidation"]
            case .xcodeProject(let scheme):
                ["cd \(projectDirectoryPath); xcodebuild clean build -scheme \"\(scheme)\" -destination \"generic/platform=iOS\" -derivedDataPath .build -sdk `xcrun --sdk iphonesimulator --show-sdk-path` BUILD_LIBRARY_FOR_DISTRIBUTION=YES"]
            }
        }()
        var expectedHandleLogCalls: [(message: String, subsystem: String)] = [
            ("📦 Archiving SCHEME from PROJECT_DIRECTORY_PATH", "XcodeTools")
        ]
        var expectedHandleDebugCalls: [(message: String, subsystem: String)] = [
            (archiveResult, "XcodeTools")
        ]
        var expectedHandleFileExistsCalls = ["PROJECT_DIRECTORY_PATH/.build"]
        
        var shell = MockShell()
        shell.handleExecute = { command in
            let expectedInput = expectedHandleExecuteCalls.removeFirst()
            XCTAssertEqual(command, expectedInput)
            return archiveResult
        }
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { path in
            let expectedInput = expectedHandleFileExistsCalls.removeFirst()
            XCTAssertEqual(path, expectedInput)
            return true
        }
        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            let expectedInput = expectedHandleLogCalls.removeFirst()
            XCTAssertEqual(message, expectedInput.message)
            XCTAssertEqual(subsystem, expectedInput.subsystem)
        }
        logger.handleDebug = { message, subsystem in
            let expectedInput = expectedHandleDebugCalls.removeFirst()
            XCTAssertEqual(message, expectedInput.message)
            XCTAssertEqual(subsystem, expectedInput.subsystem)
        }
        
        let xcodeTools = XcodeTools(
            shell: shell,
            fileHandler: fileHandler,
            logger: logger
        )
        
        let derivedDataPath = try await xcodeTools.archive(
            projectDirectoryPath: projectDirectoryPath,
            scheme: scheme,
            projectType: projectType
        )
        
        XCTAssertEqual(derivedDataPath, expectedDerivedDataPath)
        XCTAssertTrue(expectedHandleExecuteCalls.isEmpty)
        XCTAssertTrue(expectedHandleLogCalls.isEmpty)
        XCTAssertTrue(expectedHandleDebugCalls.isEmpty)
        XCTAssertTrue(expectedHandleFileExistsCalls.isEmpty)
    }
}
