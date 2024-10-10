//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 10/10/2024.
//

import Foundation

import FileHandlingModule
import ProjectSetupModule
import LoggingModule
import CoreModule
import ShellModule
import SwiftPackageFileAnalyzerModule
import SwiftInterfaceProducerModule

public struct ProjectBuilder {
    
    public struct Result {
        public let packageFileChanges: [Change]
        public let warnings: [String]
        public let swiftInterfaceFiles: [SwiftInterfaceFile]
    }
    
    private let projectType: ProjectType
    private let swiftInterfaceType: SwiftInterfaceType
    private let fileHandler: any FileHandling
    private let shell: any ShellHandling
    private let logger: (any Logging)?
    
    public init(
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
        
        // MARK: - Analyze Package.swift (optional)
        
        let warnings: [String]
        let packageFileChanges: [Change]
        
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
