//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import Testing

@Suite
struct XcodeToolsTests {

    @Test func archiveSwiftPackageiOS() async throws {

        let projectDirectoryPath = "PROJECT_DIRECTORY_PATH"

        try await testArchiving(
            projectDirectoryPath: projectDirectoryPath,
            projectType: .swiftPackage,
            platform: .iOS
        )
    }

    @Test func archiveXcodeProjectiOS() async throws {

        let projectDirectoryPath = "PROJECT_DIRECTORY_PATH"

        try await testArchiving(
            projectDirectoryPath: projectDirectoryPath,
            projectType: .xcodeProject(scheme: "SCHEME"),
            platform: .iOS
        )
    }
    
    @Test func archiveSwiftPackagemacOS() async throws {

        let projectDirectoryPath = "PROJECT_DIRECTORY_PATH"

        try await testArchiving(
            projectDirectoryPath: projectDirectoryPath,
            projectType: .swiftPackage,
            platform: .macOS
        )
    }
    
    @Test func archiveXcodeProjectmacOS() async throws {

        let projectDirectoryPath = "PROJECT_DIRECTORY_PATH"

        try await testArchiving(
            projectDirectoryPath: projectDirectoryPath,
            projectType: .xcodeProject(scheme: "SCHEME"),
            platform: .macOS
        )
    }
}

private extension XcodeToolsTests {

    func expectedCommand(projectDirectoryPath: String, scheme: String, projectType: ProjectType, platform: ProjectPlatform) -> String {
        
        var commandComponents = [
            "cd \(projectDirectoryPath);",
            "xcodebuild clean build -scheme \"\(scheme)\"",
            "-derivedDataPath .build BUILD_LIBRARY_FOR_DISTRIBUTION=YES",
            "OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface"
        ]
        
        switch platform {
        case .macOS:
            commandComponents += ["-destination \"generic/platform=macOS\""]
        case .iOS:
            commandComponents += ["-sdk `xcrun --sdk iphonesimulator --show-sdk-path` -destination \"generic/platform=iOS\""]
        }
        
        switch projectType {
        case .swiftPackage:
            commandComponents += ["-skipPackagePluginValidation"]
        case .xcodeProject:
            break // Nothing specific to add
        }
        
        return String(commandComponents.joined(separator: " "))
    }
    
    func testArchiving(
        projectDirectoryPath: String,
        projectType: ProjectType,
        platform: ProjectPlatform
    ) async throws {

        let scheme = "SCHEME"
        let archiveResult = "ARCHIVE_RESULT"
        let expectedDerivedDataPath = "\(projectDirectoryPath)/.build"
        var expectedHandleExecuteCalls: [String] = { [expectedCommand(
            projectDirectoryPath: projectDirectoryPath,
            scheme: scheme,
            projectType: projectType,
            platform: platform
        )] }()
        var expectedHandleLogCalls: [(message: String, subsystem: String)] = [
            ("📦 Archiving SCHEME from PROJECT_DIRECTORY_PATH", "XcodeTools")
        ]
        var expectedHandleDebugCalls: [(message: String, subsystem: String)] = [
            (archiveResult, "XcodeTools")
        ]
        var expectedHandleFileExistsCalls = ["PROJECT_DIRECTORY_PATH/.build/Build"]

        var shell = MockShell()
        shell.handleExecute = { command in
            let expectedInput = expectedHandleExecuteCalls.removeFirst()
            #expect(command == expectedInput)
            return archiveResult
        }
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { path in
            let expectedInput = expectedHandleFileExistsCalls.removeFirst()
            #expect(path == expectedInput)
            return true
        }
        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            let expectedInput = expectedHandleLogCalls.removeFirst()
            #expect(message == expectedInput.message)
            #expect(subsystem == expectedInput.subsystem)
        }
        logger.handleDebug = { message, subsystem in
            let expectedInput = expectedHandleDebugCalls.removeFirst()
            #expect(message == expectedInput.message)
            #expect(subsystem == expectedInput.subsystem)
        }

        let xcodeTools = XcodeTools(
            shell: shell,
            fileHandler: fileHandler,
            logger: logger
        )

        let derivedDataPath = try await xcodeTools.archive(
            projectDirectoryPath: projectDirectoryPath,
            scheme: scheme,
            projectType: projectType,
            platform: platform
        )

        #expect(derivedDataPath == expectedDerivedDataPath)
        #expect(expectedHandleExecuteCalls.isEmpty)
        #expect(expectedHandleLogCalls.isEmpty)
        #expect(expectedHandleDebugCalls.isEmpty)
        #expect(expectedHandleFileExistsCalls.isEmpty)
    }
}
