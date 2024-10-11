//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation

import PADCore
import PADLogging

import PADSwiftInterfaceDiff
import PADProjectBuilder
import PADOutputGenerator

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
        
        let logLevel: PADLogLevel = .debug
        let projectType: PADProjectType = { // Only needed when we have to produce the .swiftinterface files
            if let scheme { return .xcodeProject(scheme: scheme) }
            return .swiftPackage
        }()
        let swiftInterfaceType: PADSwiftInterfaceType = .public // Only needed when we have to produce the .swiftinterface files
        
        let logger = Self.logger(with: logLevel, logOutputFilePath: logOutput)
        
        do {
            var warnings = [String]()
            var changes = [String: [PADChange]]()
            
            // MARK: - Producing .swiftinterface files
            
            let oldSource: PADProjectSource = try .from(old)
            let newSource: PADProjectSource = try .from(new)
            
            let oldVersionName = oldSource.description
            let newVersionName = newSource.description
            
            let projectBuilder = PADProjectBuilder(
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
            
            let pipeline = PADSwiftInterfaceDiff(logger: logger)
            
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
            
            let outputGenerator: any PADOutputGenerating = PADMarkdownOutputGenerator()
            
            let generatedOutput = try outputGenerator.generate(
                from: changes,
                allTargets: projectBuilderResult.swiftInterfaceFiles.map(\.name).sorted(),
                oldVersionName: oldVersionName,
                newVersionName: newVersionName,
                warnings: warnings
            )
            
            if let output {
                try FileManager.default.write(generatedOutput, to: output)
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
    
    static func logger(
        with logLevel: PADLogLevel,
        logOutputFilePath: String?
    ) -> any PADLogging {
        var loggers = [any PADLogging]()
        if let logOutputFilePath {
            loggers += [PADLogFileLogger(outputFilePath: logOutputFilePath)]
        }
        loggers += [PADSystemLogger().withLogLevel(logLevel)]
        
        return PADLoggingGroup(with: loggers)
    }
}
