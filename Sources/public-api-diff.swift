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
        
        let logLevel: LogLevel = .debug
        let projectType: ProjectType = { // Only needed when we have to produce the .swiftinterface files
            if let scheme { return .xcodeProject(scheme: scheme) }
            return .swiftPackage
        }()
        let swiftInterfaceType: SwiftInterfaceType = .public // Only needed when we have to produce the .swiftinterface files
        
        let fileHandler: FileHandling = FileManager.default
        let shell: any ShellHandling = Shell()
        let logger = Self.logger(with: logLevel, logOutputFilePath: logOutput, fileHandler: fileHandler)
        
        do {
            var warnings = [String]()
            var changes = [String: [Change]]()
            
            // MARK: START: BUILD PROJECT RELATED
            
            let oldSource: ProjectSource = try ProjectSource.from(old, fileHandler: fileHandler)
            let newSource: ProjectSource = try ProjectSource.from(new, fileHandler: fileHandler)
            
            let oldVersionName = oldSource.description
            let newVersionName = newSource.description
            
            logger.log("Comparing `\(newVersionName)` to `\(oldVersionName)`", from: "Main")
            
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
            
            switch projectType {
            case .swiftPackage:
                let swiftPackageFileAnalyzer = SwiftPackageFileAnalyzer(fileHandler: fileHandler, shell: shell, logger: logger)
                let swiftPackageAnalysis = try swiftPackageFileAnalyzer.analyze(
                    oldProjectUrl: projectDirectories.old,
                    newProjectUrl: projectDirectories.new
                )
                
                warnings = swiftPackageAnalysis.warnings
                if !swiftPackageAnalysis.changes.isEmpty {
                    changes["Package.swift"] = swiftPackageAnalysis.changes
                }
            case .xcodeProject:
                warnings = []
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
            
            // MARK: - Analyze .swiftinterface files
            
            let pipeline = SwiftInterfacePipeline(
                fileHandler: fileHandler,
                swiftInterfaceParser: SwiftInterfaceParser(),
                swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
                logger: logger
            )
            
            let pipelineOutput = try await pipeline.run(
                with: swiftInterfaceFiles
            )
            
            // Merging pipeline output into existing changes - making sure we're not overriding any keys
            pipelineOutput.forEach { key, value in
                var keyToUse = key
                if changes[key] != nil {
                    keyToUse = "\(key) (\(UUID().uuidString))"
                }
                changes[keyToUse] = value
            }
            
            // MARK: - Generate Output
            
            let outputGenerator: any OutputGenerating = MarkdownOutputGenerator()
            
            let generatedOutput = try outputGenerator.generate(
                from: changes,
                allTargets: swiftInterfaceFiles.map(\.name).sorted(),
                oldVersionName: oldVersionName,
                newVersionName: newVersionName,
                warnings: warnings
            )
            
            if let output {
                try fileHandler.write(generatedOutput, to: output)
            } else {
                // We're not using a logger here as we always want to have it printed if no output was specified
                print(generatedOutput)
            }
            
            logger.log("✅ Success", from: "Main")
        } catch {
            logger.log("💥 \(error.localizedDescription)", from: "Main")
        }
    }
}

private extension PublicApiDiff {
    
    static func logger(with logLevel: LogLevel, logOutputFilePath: String?, fileHandler: any FileHandling) -> any Logging {
        var loggers = [any Logging]()
        if let logOutputFilePath {
            loggers += [LogFileLogger(fileHandler: fileHandler, outputFilePath: logOutputFilePath)]
        }
        loggers += [SystemLogger().withLogLevel(logLevel)]
        
        return LoggingGroup(with: loggers)
    }
}
