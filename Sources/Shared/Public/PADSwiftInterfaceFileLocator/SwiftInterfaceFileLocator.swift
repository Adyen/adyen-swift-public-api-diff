//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import FileHandlingModule
import PADLogging
import ShellModule

/// A helper to locate `.swiftinterface` files
public struct SwiftInterfaceFileLocator {

    let fileHandler: any FileHandling
    let shell: any ShellHandling
    let logger: (any Logging)?

    package init(
        fileHandler: any FileHandling,
        shell: any ShellHandling,
        logger: (any Logging)?
    ) {
        self.fileHandler = fileHandler
        self.shell = shell
        self.logger = logger
    }

    public init(
        logger: (any Logging)? = nil
    ) {
        self.init(
            fileHandler: FileManager.default,
            shell: Shell(logger: logger),
            logger: logger
        )
    }

    /// Tries to locate a `.swiftinterface` files in the derivedData folder for a specific scheme
    /// - Parameters:
    ///   - scheme: The scheme to find the `.swiftinterface` file for
    ///   - derivedDataPath: The path to the derived data directory (e.g. .../.build)
    ///   - type: The swift interface type (.public, .private) to look for
    /// - Returns: The file url to the found `.swiftinterface`
    /// - Throws: An error if no `.swiftinterface` file can be found for the given scheme + derived data path
    public func locate(for scheme: String, derivedDataPath: String, type: SwiftInterfaceType) throws -> URL {
        let schemeSwiftModuleName = "\(scheme).swiftmodule"

        let swiftModulePathsForScheme = shell.execute("cd '\(derivedDataPath)'; find . -type d -name '\(schemeSwiftModuleName)'")
            .components(separatedBy: .newlines)
            .map { URL(filePath: derivedDataPath).appending(path: $0) }

        guard let swiftModulePath = swiftModulePathsForScheme.first?.path() else {
            throw FileHandlerError.pathDoesNotExist(path: "find . -type d -name '\(schemeSwiftModuleName)'")
        }

        let swiftModuleContent = try fileHandler.contentsOfDirectory(atPath: swiftModulePath)

        let swiftInterfacePaths: [String]
        switch type {
        case .private, .package:
            swiftInterfacePaths = swiftModuleContent.filter { $0.hasSuffix(".\(type.fileExtension)") }
        case .public:
            swiftInterfacePaths = swiftModuleContent.filter {
                $0.hasSuffix(".\(SwiftInterfaceType.public.fileExtension)") &&
                !$0.hasSuffix(".\(SwiftInterfaceType.private.fileExtension)") &&
                !$0.hasSuffix(".\(SwiftInterfaceType.package.fileExtension)")
            }
        }

        guard let swiftInterfacePath = swiftInterfacePaths.first else {
            throw FileHandlerError.pathDoesNotExist(
                path: "'\(swiftModulePath)/\(scheme).\(type.fileExtension)'"
            )
        }

        return URL(filePath: swiftModulePath).appending(path: swiftInterfacePath)
    }
}
