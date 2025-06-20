//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import FileHandlingModule
import PADCore
import PADLogging
import ShellModule

struct XcodeToolsError: LocalizedError, CustomDebugStringConvertible {
    var errorDescription: String
    var underlyingError: String

    var debugDescription: String { errorDescription }
}

/// A helper that provides tools to build a project
struct XcodeTools {

    internal enum Constants {
        static let derivedDataPath: String = ".build"
        static let buildDirPath: String = ".build/Build"
        static let simulatorSdkCommand = "xcrun --sdk iphonesimulator --show-sdk-path"
    }

    private let shell: ShellHandling
    private let fileHandler: FileHandling
    private let logger: Logging?

    init(
        shell: ShellHandling,
        fileHandler: FileHandling = FileManager.default,
        logger: Logging?
    ) {
        self.shell = shell
        self.fileHandler = fileHandler
        self.logger = logger
    }

    /// Archives a project at the specified path / scheme by building for library evolution
    /// - Parameters:
    ///   - projectDirectoryPath: The path to the project root directory
    ///   - scheme: The scheme/target to build
    ///   - projectType: The type of the project
    /// - Returns: The derived data directory path
    func archive(
        projectDirectoryPath: String,
        scheme: String,
        projectType: ProjectType,
        platform: ProjectPlatform
    ) async throws -> String {
        
        var commandComponents = [
            "cd \(projectDirectoryPath);",
            "xcodebuild clean build -scheme \"\(scheme)\"",
            "-derivedDataPath \(Constants.derivedDataPath)",
            "BUILD_LIBRARY_FOR_DISTRIBUTION=YES",
            "OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface"
        ]
        
        switch platform {
        case .iOS:
            commandComponents += [
                "-sdk `\(Constants.simulatorSdkCommand)`",
                "-destination \"generic/platform=iOS\""
            ]
        case .macOS:
            commandComponents += [
                "-destination \"generic/platform=macOS\""
            ]
        }

        switch projectType {
        case .swiftPackage:
            commandComponents += ["-skipPackagePluginValidation"]
        case .xcodeProject:
            break // Nothing to add
        }

        let command = commandComponents.joined(separator: " ")
        
        return try await Task {
            logger?.log("📦 Archiving \(scheme) from \(projectDirectoryPath)", from: String(describing: Self.self))

            let result = shell.execute(command)
            let derivedDataPath = "\(projectDirectoryPath)/\(Constants.derivedDataPath)"
            let buildDirPath = "\(projectDirectoryPath)/\(Constants.buildDirPath)"

            logger?.debug(result, from: String(describing: Self.self))

            // It might be that the archive failed but the .swiftinterface files are still created
            // so we have to check outside if they exist.
            //
            // Also see: https://github.com/swiftlang/swift/issues/56573
            guard fileHandler.fileExists(atPath: buildDirPath) else {
                throw XcodeToolsError(
                    errorDescription: "💥 Building project failed",
                    underlyingError: result
                )
            }

            return derivedDataPath
        }.value
    }
}
