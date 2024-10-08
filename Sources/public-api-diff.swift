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
    
    @Option(help: "Where to output the logs (File path)")
    public var logOutput: String?
    
    @Option(help: "Which scheme to build (Needed when comparing 2 swift frameworks)")
    public var scheme: String?
    
    public func run() async throws {
        
        let fileHandler: FileHandling = FileManager.default
        var loggers = [any Logging]()
        if let logOutput {
            loggers += [LogFileLogger(fileHandler: fileHandler, outputFilePath: logOutput)]
        }
        loggers += [SystemLogger(logLevel: .debug)] // LogLevel should be provided by a parameter
        
        let logger: any Logging = LoggingGroup(with: loggers)
        
        do {
            let oldSource = try ProjectSource.from(old, fileHandler: fileHandler)
            let newSource = try ProjectSource.from(new, fileHandler: fileHandler)
            
            let xcodeTools = XcodeTools(logger: logger)
            logger.log("Comparing `\(newSource.description)` to `\(oldSource.description)`", from: "Main")
            
            let currentDirectory = fileHandler.currentDirectoryPath
            let workingDirectoryPath = currentDirectory.appending("/tmp-public-api-diff")
            
            // MARK: - Generate the .swiftinterface files on the fly (optional)
            // TODO: Allow passing of .swiftinterface files
            
            let projectType: ProjectType = .swiftPackage
            let swiftInterfaceType: SwiftInterfaceType = .public
            
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
            
            logger.log("✅ Success", from: "Main")
        } catch {
            logger.log("💥 \(error.localizedDescription)", from: "Main")
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
        swiftInterfaceType: SwiftInterfaceType,
        workingDirectoryPath: String,
        fileHandler: any FileHandling,
        xcodeTools: XcodeTools,
        logger: (any Logging)?
    ) async throws -> [SwiftInterfacePipeline.SwiftInterfaceFile] {
        
        let newProjectDirectoryPath = newProjectUrl.path()
        let oldProjectDirectoryPath = oldProjectUrl.path()
        
        let (archiveScheme, schemesToCompare) = try prepareProjectsForArchiving(
            newProjectDirectoryPath: newProjectDirectoryPath,
            oldProjectDirectoryPath: oldProjectDirectoryPath,
            projectType: projectType,
            fileHandler: fileHandler,
            xcodeTools: xcodeTools
        )
        
        let (newDerivedDataPath, oldDerivedDataPath) = try await archiveProjects(
            newProjectDirectoryPath: newProjectDirectoryPath,
            oldProjectDirectoryPath: oldProjectDirectoryPath,
            scheme: archiveScheme,
            projectType: projectType,
            xcodeTools: xcodeTools
        )
        
        return try locateInterfaceFiles(
            newDerivedDataPath: newDerivedDataPath,
            oldDerivedDataPath: oldDerivedDataPath,
            schemes: schemesToCompare,
            swiftInterfaceType: swiftInterfaceType,
            logger: logger
        )
    }
    
    func prepareProjectsForArchiving(
        newProjectDirectoryPath: String,
        oldProjectDirectoryPath: String,
        projectType: ProjectType,
        fileHandler: any FileHandling,
        xcodeTools: XcodeTools
    ) throws -> (archiveScheme: String, schemesToCompare: [String]) { // TODO: Typed return type
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
            
            schemesToCompare = newTargets.intersection(oldTargets).sorted()
            
            if schemesToCompare.isEmpty {
                throw PipelineError.noTargetFound
            }
            
        case .xcodeProject:
            guard let scheme else {
                throw PipelineError.noTargetFound // TODO: Better error!
            }
            archiveScheme = scheme
            schemesToCompare = [scheme]
        }
        
        return (archiveScheme, schemesToCompare)
    }
    
    func archiveProjects(
        newProjectDirectoryPath: String,
        oldProjectDirectoryPath: String,
        scheme: String,
        projectType: ProjectType,
        xcodeTools: XcodeTools
    ) async throws -> (newDerivedDataPath: String, oldDerivedDataPath: String) { // TODO: Typed return type
        async let asyncNewDerivedDataPath = try xcodeTools.archive(
            projectDirectoryPath: newProjectDirectoryPath,
            scheme: scheme,
            projectType: projectType
        )
        async let asyncOldDerivedDataPath = try xcodeTools.archive(
            projectDirectoryPath: oldProjectDirectoryPath,
            scheme: scheme,
            projectType: projectType
        )
        
        return try await (asyncNewDerivedDataPath, asyncOldDerivedDataPath)
    }
    
    func locateInterfaceFiles(
        newDerivedDataPath: String,
        oldDerivedDataPath: String,
        schemes schemesToCompare: [String],
        swiftInterfaceType: SwiftInterfaceType,
        logger: (any Logging)?
    ) throws -> [SwiftInterfacePipeline.SwiftInterfaceFile] {
        logger?.log("🔎 Locating interface files for \(schemesToCompare.joined(separator: ", "))", from: "Main")
        
        // TODO: Ideally concatenate all .swiftinterface files so all the information is in one file
        // and cross-module extensions can be applied correctly
        
        let interfaceFileLocator = SwiftInterfaceFileLocator(logger: logger)
        return schemesToCompare.compactMap { scheme in
            do {
                let newSwiftInterfaceUrl = try interfaceFileLocator.locate(for: scheme, derivedDataPath: newDerivedDataPath, type: swiftInterfaceType)
                let oldSwiftInterfaceUrl = try interfaceFileLocator.locate(for: scheme, derivedDataPath: oldDerivedDataPath, type: swiftInterfaceType)
                return .init(name: scheme, oldFilePath: oldSwiftInterfaceUrl.path(), newFilePath: newSwiftInterfaceUrl.path())
            } catch {
                logger?.log("👻 \(error.localizedDescription)", from: "Main")
                return nil
            }
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
