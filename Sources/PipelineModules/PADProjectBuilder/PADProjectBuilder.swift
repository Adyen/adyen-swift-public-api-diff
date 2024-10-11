import Foundation

import PADLogging
import PADCore

import ShellModule
import FileHandlingModule

public struct PADProjectBuilder {
    
    public struct Result {
        public let packageFileChanges: [PADChange]
        public let warnings: [String]
        public let swiftInterfaceFiles: [PADSwiftInterfaceFile]
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
        
        // MARK: - Analyze Package.swift (optional)
        
        let warnings: [String]
        let packageFileChanges: [PADChange]
        
        switch projectType {
        case .swiftPackage:
            let swiftPackageFileAnalyzer = SwiftPackageFileAnalyzer(
                fileHandler: fileHandler,
                shell: shell,
                logger: logger
            )
            let swiftPackageAnalysis = try swiftPackageFileAnalyzer.analyze(
                oldProjectUrl: projectDirectories.old,
                newProjectUrl: projectDirectories.new
            )
            
            warnings = swiftPackageAnalysis.warnings
            packageFileChanges = swiftPackageAnalysis.changes
        case .xcodeProject:
            warnings = []
            packageFileChanges = []
            break // Nothing to do
        }
        
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
            packageFileChanges: packageFileChanges,
            warnings: warnings,
            swiftInterfaceFiles: swiftInterfaceFiles
        )
    }
}
