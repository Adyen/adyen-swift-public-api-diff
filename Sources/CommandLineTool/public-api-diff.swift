//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation

import LoggingModule
import FileHandlingModule
import CoreModule
import ProjectSetupModule
import ShellModule
import SwiftInterfaceProducerModule
import SwiftInterfaceAnalyzerModule
import OutputGeneratorModule
import ProjectBuilderModule

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
            
            let oldSource: ProjectSource = try ProjectSource.from(old, fileHandler: fileHandler)
            let newSource: ProjectSource = try ProjectSource.from(new, fileHandler: fileHandler)
            
            let oldVersionName = oldSource.description
            let newVersionName = newSource.description
            
            // MARK: - Producing .swiftinterface files
            
            let projectBuilder = ProjectBuilder(
                projectType: projectType,
                swiftInterfaceType: swiftInterfaceType,
                logger: logger
            )
            
            let projectBuilderResult = try await projectBuilder.build(
                oldSource: oldSource,
                newSource: newSource
            )
            
            warnings += projectBuilderResult.warnings
            if !projectBuilderResult.packageFileChanges.isEmpty {
                changes["Package.swift"] = projectBuilderResult.packageFileChanges
            }
            
            // MARK: - Analyze .swiftinterface files
            
            let pipeline = SwiftInterfacePipeline(logger: logger)
            
            let pipelineOutput = try await pipeline.run(
                with: projectBuilderResult.swiftInterfaceFiles
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
                allTargets: projectBuilderResult.swiftInterfaceFiles.map(\.name).sorted(),
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
