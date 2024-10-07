//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation

@main
struct PublicApiDiff: AsyncParsableCommand {
    
    @Option(help: "Specify the updated version to compare to")
    public var new: String
    
    @Option(help: "Specify the old version to compare to")
    public var old: String
    
    @Option(help: "Where to output the result (File path)")
    public var output: String?
    
    @Option(help: "Which scheme to build (Needed when comparing 2 swift frameworks)")
    public var scheme: String?
    
    public func run() async throws {
        
        let fileHandler: FileHandling = FileManager.default
        let oldSource = try ProjectSource.from(old, fileHandler: fileHandler)
        let newSource = try ProjectSource.from(new, fileHandler: fileHandler)
        let logger: any Logging = PipelineLogger(logLevel: .debug) // LogLevel should be provided by a parameter
        let xcodeTools = XcodeTools(logger: logger)
        logger.log("Comparing `\(newSource.description)` to `\(oldSource.description)`", from: "Main")
        
        let currentDirectory = fileHandler.currentDirectoryPath
        let workingDirectoryPath = currentDirectory.appending("/tmp-public-api-diff")
        
        // MARK: - Generate the .swiftinterface files on the fly (optional)
        // TODO: Allow passing of .swiftinterface files
        
        let projectType: ProjectType = .swiftPackage
        let swiftInterfaceType: SwiftInterfaceFileLocator.SwiftInterfaceType = .public
        
        let (oldProjectUrl, newProjectUrl) = try await setupProject(
            oldSource: oldSource,
            newSource: newSource,
            workingDirectoryPath: workingDirectoryPath,
            projectType: projectType,
            logger: logger
        )
        
        let swiftInterfaceFiles = try await generateSwiftInterfaceFiles(
            newProjectUrl: newProjectUrl,
            oldProjectUrl: oldProjectUrl,
            projectType: projectType,
            swiftInterfaceType: swiftInterfaceType,
            workingDirectoryPath: workingDirectoryPath,
            fileHandler: fileHandler,
            xcodeTools: xcodeTools,
            logger: logger
        )
        
        // MARK: - Analyze .swiftinterface files
        
        var changes = try await SwiftInterfacePipeline(
            swiftInterfaceFiles: swiftInterfaceFiles,
            fileHandler: fileHandler,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
            logger: logger
        ).run()
        
        // MARK: - Analyze Package.swift (optional)
        
        let swiftPackageFileAnalyzer = SwiftPackageFileAnalyzer(logger: logger)
        let swiftPackageAnalysis = try swiftPackageFileAnalyzer.analyze(
            oldProjectUrl: oldProjectUrl,
            newProjectUrl: newProjectUrl
        )
        
        if !swiftPackageAnalysis.changes.isEmpty {
            changes["Package.swift"] = swiftPackageAnalysis.changes
        }
        
        let allTargets = swiftInterfaceFiles.map(\.name)
        
        // MARK: - Generate Output (optional)
        
        let markdownOutput =  MarkdownOutputGenerator().generate(
            from: changes,
            allTargets: allTargets.sorted(),
            oldSource: oldSource,
            newSource: newSource,
            warnings: swiftPackageAnalysis.warnings
        )
        
        if let output {
            try fileHandler.write(markdownOutput, to: output)
        } else {
            // We're not using a logger here as we always want to have it printed if no output was specified
            print(markdownOutput)
        }
    }
}

private extension PublicApiDiff {
    
    func setupProject(
        oldSource: ProjectSource,
        newSource: ProjectSource,
        workingDirectoryPath: String,
        projectType: ProjectType,
        logger: (any Logging)?
    ) async throws -> (old: URL, new: URL) {
        let projectSetupHelper = ProjectSetupHelper(
            workingDirectoryPath: workingDirectoryPath,
            logger: logger
        )
        
        // async let to make them perform in parallel
        async let asyncNewProjectDirectoryPath = try projectSetupHelper.setup(newSource, projectType: projectType)
        async let asyncOldProjectDirectoryPath = try projectSetupHelper.setup(oldSource, projectType: projectType)
        
        return try await (URL(filePath: asyncOldProjectDirectoryPath), URL(filePath: asyncNewProjectDirectoryPath))
    }
    
    // TODO: Move this to it's own pipeline that can be used optionally
    func generateSwiftInterfaceFiles(
        newProjectUrl: URL,
        oldProjectUrl: URL,
        projectType: ProjectType,
        swiftInterfaceType: SwiftInterfaceFileLocator.SwiftInterfaceType,
        workingDirectoryPath: String,
        fileHandler: any FileHandling,
        xcodeTools: XcodeTools,
        logger: (any Logging)?
    ) async throws -> [SwiftInterfacePipeline.SwiftInterfaceFile] {
        
        let newProjectDirectoryPath = newProjectUrl.path()
        let oldProjectDirectoryPath = oldProjectUrl.path()
        
        let archiveScheme: String
        let schemesToCompare: [String]
        
        switch projectType {
        case .swiftPackage:
            archiveScheme = "_AllTargets"
            let packageFileHelper = SwiftPackageFileHelper(fileHandler: fileHandler, xcodeTools: xcodeTools)
            try packageFileHelper
                .preparePackageWithConsolidatedLibrary(named: archiveScheme, at: newProjectDirectoryPath)
            try packageFileHelper
                .preparePackageWithConsolidatedLibrary(named: archiveScheme, at: oldProjectDirectoryPath)
            
            let newTargets = try Set(packageFileHelper.availableTargets(at: newProjectDirectoryPath))
            let oldTargets = try Set(packageFileHelper.availableTargets(at: oldProjectDirectoryPath))
            
            schemesToCompare = newTargets.intersection(oldTargets).sorted() // TODO: Handle added/removed targets
            
        case .xcodeProject:
            guard let scheme else {
                throw PipelineError.noTargetFound // TODO: Better error!
            }
            archiveScheme = scheme
            schemesToCompare = [scheme]
        }
        
        async let asyncNewDerivedDataPath = try xcodeTools.archive(projectDirectoryPath: newProjectDirectoryPath, scheme: archiveScheme)
        async let asyncOldDerivedDataPath = try xcodeTools.archive(projectDirectoryPath: oldProjectDirectoryPath, scheme: archiveScheme)
        
        let newDerivedDataPath = try await asyncNewDerivedDataPath
        let oldDerivedDataPath = try await asyncOldDerivedDataPath
        
        return try schemesToCompare.compactMap { scheme in
            // Locating swift interface files
            let interfaceFileLocator = SwiftInterfaceFileLocator()
            let newSwiftInterfacePaths = try interfaceFileLocator.locate(for: scheme, derivedDataPath: newDerivedDataPath, type: swiftInterfaceType)
            let oldSwiftInterfacePaths = try interfaceFileLocator.locate(for: scheme, derivedDataPath: oldDerivedDataPath, type: swiftInterfaceType)
            
            guard
                let oldFilePath = oldSwiftInterfacePaths.first?.path(),
                let newFilePath = newSwiftInterfacePaths.first?.path()
            else {
                return nil
            }
            
            return .init(name: scheme, oldFilePath: oldFilePath, newFilePath: newFilePath)
        }
    }
}

internal extension SDKDumpPipeline {
    
    static func run(
        newSource: ProjectSource,
        oldSource: ProjectSource,
        scheme: String?,
        workingDirectoryPath: String,
        fileHandler: FileHandling,
        logger: Logging?
    ) async throws -> String {
        
        defer {
            logger?.debug("Cleaning up", from: "Main")
            try? fileHandler.removeItem(atPath: workingDirectoryPath)
        }
        
        return try await SDKDumpPipeline(
            newProjectSource: newSource,
            oldProjectSource: oldSource,
            scheme: scheme,
            projectBuilder: ProjectBuilder(baseWorkingDirectoryPath: workingDirectoryPath, logger: logger),
            abiGenerator: ABIGenerator(logger: logger),
            projectAnalyzer: SwiftPackageFileAnalyzer(logger: logger),
            sdkDumpGenerator: SDKDumpGenerator(),
            sdkDumpAnalyzer: SDKDumpAnalyzer(),
            outputGenerator: MarkdownOutputGenerator(),
            logger: logger
        ).run()
    }
}
