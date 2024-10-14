import Foundation

import PADLogging
import PADCore

import ShellModule
import FileHandlingModule

/// The ``PADProjectBuilder/PADProjectBuilder`` builds the old & new project and outputs a list
/// of ``PADCore/PADSwiftInterfaceFile``s as well as changes that happened to the
/// project files including any warnings if applicable.
///
/// Following tasks are performed:
/// - Fetch remote projects (if applicable)
/// - Archiving projects
/// - Inspecting `Package.swift` for any changes between versions (if applicable / if ``PADProjectType/swiftPackage``)
/// - Returning a ``PADProjectBuilder/PADProjectBuilder/Result`` containing package file changes, warnings + the found ``PADCore/PADSwiftInterfaceFile``s
public struct PADProjectBuilder {
    
    /// The result returned by the build function of ``PADProjectBuilder/PADProjectBuilder``
    public struct Result {
        /// The `.swiftinterface` file references found
        public let swiftInterfaceFiles: [PADSwiftInterfaceFile]
        /// The project directories for the setup projects
        public let projectDirectories: (old: URL, new: URL)
    }
    
    private let projectType: PADProjectType
    private let swiftInterfaceType: PADSwiftInterfaceType
    private let fileHandler: any FileHandling
    private let shell: any ShellHandling
    private let logger: (any PADLogging)?
    
    public init(
        projectType: PADProjectType,
        swiftInterfaceType: PADSwiftInterfaceType,
        logger: (any PADLogging)? = nil
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
        projectType: PADProjectType,
        swiftInterfaceType: PADSwiftInterfaceType,
        fileHandler: any FileHandling = FileManager.default,
        shell: any ShellHandling = Shell(),
        logger: (any PADLogging)?
    ) {
        self.projectType = projectType
        self.swiftInterfaceType = swiftInterfaceType
        self.fileHandler = fileHandler
        self.shell = shell
        self.logger = logger
    }
    
    public func build(
        oldSource: PADProjectSource,
        newSource: PADProjectSource
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
