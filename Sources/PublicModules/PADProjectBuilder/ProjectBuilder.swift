//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import PADCore
import PADLogging
import PADSwiftInterfaceFileLocator

import FileHandlingModule
import ShellModule

/// The ``PADProjectBuilder/ProjectBuilder`` builds the old & new project and outputs a list
/// of ``PADCore/SwiftInterfaceFile``s as well as changes that happened to the
/// project files including any warnings if applicable.
///
/// Following tasks are performed:
/// - Fetch remote projects (if applicable)
/// - Archiving projects
/// - Inspecting `Package.swift` for any changes between versions (if applicable / if ``ProjectType/swiftPackage``)
/// - Returning a ``PADProjectBuilder/ProjectBuilder/Result`` containing package file changes, warnings + the found ``PADCore/SwiftInterfaceFile``s
public struct ProjectBuilder {
    
    /// The result returned by the build function of ``PADProjectBuilder/ProjectBuilder``
    public struct Result {
        /// The `.swiftinterface` file references found
        public let swiftInterfaceFiles: [SwiftInterfaceFile]
        /// The project directories for the setup projects
        public let projectDirectories: (old: URL, new: URL)
    }
    
    private let projectType: ProjectType
    private let swiftInterfaceType: SwiftInterfaceType
    private let fileHandler: any FileHandling
    private let shell: any ShellHandling
    private let logger: (any Logging)?
    
    public init(
        projectType: ProjectType,
        swiftInterfaceType: SwiftInterfaceType,
        logger: (any Logging)? = nil
    ) {
        self.init(
            projectType: projectType,
            swiftInterfaceType: swiftInterfaceType,
            fileHandler: FileManager.default,
            shell: Shell(),
            logger: logger
        )
    }
    
    init(
        projectType: ProjectType,
        swiftInterfaceType: SwiftInterfaceType,
        fileHandler: any FileHandling = FileManager.default,
        shell: any ShellHandling = Shell(),
        logger: (any Logging)?
    ) {
        self.projectType = projectType
        self.swiftInterfaceType = swiftInterfaceType
        self.fileHandler = fileHandler
        self.shell = shell
        self.logger = logger
    }
    
    public func build(
        oldSource: ProjectSource,
        newSource: ProjectSource
    ) async throws -> Result {
        
        let oldVersionName = oldSource.description
        let newVersionName = newSource.description
        
        logger?.log("Comparing `\(newVersionName)` to `\(oldVersionName)`", from: "Main")
        
        let currentDirectory = fileHandler.currentDirectoryPath
        let workingDirectoryPath = currentDirectory.appending("/tmp-public-api-diff")
        
        // MARK: - Setup projects
        
        let projectSetupHelper = ProjectSetupHelper(
            workingDirectoryPath: workingDirectoryPath,
            shell: shell,
            fileHandler: fileHandler,
            logger: logger
        )
        
        let projectDirectories = try await projectSetupHelper.setupProjects(
            oldSource: oldSource,
            newSource: newSource,
            projectType: projectType
        )
        
        // MARK: - Produce .swiftinterface files
        
        let producer = SwiftInterfaceProducer(
            workingDirectoryPath: workingDirectoryPath,
            projectType: projectType,
            swiftInterfaceType: swiftInterfaceType,
            fileHandler: fileHandler,
            shell: shell,
            logger: logger
        )
        
        let swiftInterfaceFiles = try await producer.produceInterfaceFiles(
            oldProjectDirectory: projectDirectories.old,
            newProjectDirectory: projectDirectories.new
        )
        
        return .init(
            swiftInterfaceFiles: swiftInterfaceFiles,
            projectDirectories: projectDirectories
        )
    }
}
