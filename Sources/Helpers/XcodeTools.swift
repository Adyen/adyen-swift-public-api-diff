//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

struct XcodeToolsError: LocalizedError, CustomDebugStringConvertible {
    var errorDescription: String
    var underlyingError: String
    
    var debugDescription: String { errorDescription }
}

struct XcodeTools {
    
    internal enum Constants {
        static let deviceTarget: String = "x86_64-apple-ios17.4-simulator" // TODO: Match the iOS version to the sdk
        static let derivedDataPath: String = ".build"
        static let simulatorSdkCommand = "xcrun --sdk iphonesimulator --show-sdk-path"
    }
    
    private let shell: ShellHandling
    private let fileHandler: FileHandling
    private let logger: Logging?
    
    init(
        shell: ShellHandling = Shell(),
        fileHandler: FileHandling = FileManager.default,
        logger: Logging?
    ) {
        self.shell = shell
        self.fileHandler = fileHandler
        self.logger = logger
    }
    
    func archive(
        projectDirectoryPath: String,
        scheme: String,
        projectType: ProjectType
    ) async throws -> String {
        var commandComponents = [
            "cd \(projectDirectoryPath);",
            "xcodebuild clean build -scheme \"\(scheme)\"",
            "-destination \"generic/platform=iOS\"",
            "-derivedDataPath \(Constants.derivedDataPath)",
            "-sdk `\(Constants.simulatorSdkCommand)`",
            "BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        ]
        
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
            
            logger?.debug(result, from: String(describing: Self.self))
            
            // It might be that the archive failed but the .swiftinterface files are still created
            // so we have to check outside if they exist.
            //
            // Also see: https://github.com/swiftlang/swift/issues/56573
            guard fileHandler.fileExists(atPath: derivedDataPath) else {
                print(result)
                
                throw XcodeToolsError(
                    errorDescription: "💥 Building project failed",
                    underlyingError: result
                )
            }
            
            return derivedDataPath
        }.value
    }
    
    private var iOSTarget: String {
        "-sdk `\(Constants.simulatorSdkCommand)` -target \(Constants.deviceTarget)"
    }
}
