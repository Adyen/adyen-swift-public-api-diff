//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation

import PADCore
import PADLogging
import PADSwiftInterfaceFileLocator

import PADOutputGenerator
import PADPackageFileAnalyzer
import PADProjectBuilder
import PADSwiftInterfaceDiff

/// Command that analyzes the differences between an old and new project and produces a human readable output
struct ProjectToOutputCommand: AsyncParsableCommand {

    static var configuration: CommandConfiguration = .init(commandName: "project")

    /// The representation of the new/updated project source
    @Option(help: "Specify the updated version to compare to")
    public var new: String

    /// The representation of the old/reference project source
    @Option(help: "Specify the old version to compare to")
    public var old: String

    /// The (optional) scheme to build
    ///
    /// Needed when comparing 2 xcode projects
    @Option(help: "[Optional] Which scheme to build (Needed when comparing 2 xcode projects)")
    public var scheme: String?

    @Option(help: "[Optional] Specify the type of .swiftinterface you want to compare (public/private)")
    public var swiftInterfaceType: SwiftInterfaceType = .public

    /// The (optional) output file path
    ///
    /// If not defined the output will be printed to the console
    @Option(help: "[Optional] Where to output the result (File path)")
    public var output: String?

    /// The (optional) path to the log output file
    @Option(help: "[Optional] Where to output the logs (File path)")
    public var logOutput: String?

    @Option(help: "[Optional] The log level to use during execution")
    public var logLevel: LogLevel = .default

    /// Entry point of the command line tool
    public func run() async throws {

        let projectType: ProjectType = {
            if let scheme { return .xcodeProject(scheme: scheme) }
            return .swiftPackage
        }()

        let logger = PublicApiDiff.logger(with: logLevel, logOutputFilePath: logOutput)

        do {
            var warnings = [String]()
            var projectChanges = [Change]()

            let oldSource: ProjectSource = try .from(old)
            let newSource: ProjectSource = try .from(new)

            // MARK: - Producing .swiftinterface files

            let projectBuilderResult = try await Self.buildProject(
                oldSource: oldSource,
                newSource: newSource,
                projectType: projectType,
                swiftInterfaceType: swiftInterfaceType,
                logger: logger
            )

            // MARK: - Analyzing .swiftinterface files

            let swiftInterfaceChanges = try await Self.analyzeSwiftInterfaceFiles(
                swiftInterfaceFiles: projectBuilderResult.swiftInterfaceFiles,
                logger: logger
            )

            // MARK: - Analyzing Package.swift

            try Self.analyzeProject(
                ofType: projectType,
                projectDirectories: projectBuilderResult.projectDirectories,
                changes: &projectChanges,
                warnings: &warnings,
                logger: logger
            )

            // MARK: - Merging Changes

            var changes = swiftInterfaceChanges
            if !projectChanges.isEmpty {
                changes["Package.swift"] = projectChanges
            }

            // MARK: - Generate Output

            let generatedOutput = try Self.generateOutput(
                for: changes,
                warnings: warnings,
                allTargets: projectBuilderResult.swiftInterfaceFiles.map(\.name).sorted(),
                oldVersionName: oldSource.title,
                newVersionName: newSource.title
            )

            // MARK: -

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

// MARK: - Privates

private extension ProjectToOutputCommand {

    static func buildProject(
        oldSource: ProjectSource,
        newSource: ProjectSource,
        projectType: ProjectType,
        swiftInterfaceType: SwiftInterfaceType,
        logger: any Logging
    ) async throws -> ProjectBuilder.Result {

        let projectBuilder = ProjectBuilder(
            projectType: projectType,
            swiftInterfaceType: swiftInterfaceType,
            logger: logger
        )

        return try await projectBuilder.build(
            oldSource: oldSource,
            newSource: newSource
        )
    }

    static func analyzeProject(
        ofType projectType: ProjectType,
        projectDirectories: (old: URL, new: URL),
        changes: inout [Change],
        warnings: inout [String],
        logger: any Logging
    ) throws {
        switch projectType {
        case .swiftPackage:
            let swiftPackageFileAnalyzer = SwiftPackageFileAnalyzer(
                logger: logger
            )
            let swiftPackageAnalysis = try swiftPackageFileAnalyzer.analyze(
                oldProjectUrl: projectDirectories.old,
                newProjectUrl: projectDirectories.new
            )

            warnings = swiftPackageAnalysis.warnings
            changes = swiftPackageAnalysis.changes
        case .xcodeProject:
            warnings = []
            changes = []
            // Nothing to do
        }
    }

    static func analyzeSwiftInterfaceFiles(
        swiftInterfaceFiles: [SwiftInterfaceFile],
        logger: any Logging
    ) async throws -> [String: [Change]] {
        let swiftInterfaceDiff = SwiftInterfaceDiff(logger: logger)

        return try await swiftInterfaceDiff.run(
            with: swiftInterfaceFiles
        )
    }

    static func generateOutput(
        for changes: [String: [Change]],
        warnings: [String],
        allTargets: [String],
        oldVersionName: String,
        newVersionName: String
    ) throws -> String {
        let outputGenerator: any OutputGenerating<String> = MarkdownOutputGenerator()

        return try outputGenerator.generate(
            from: changes,
            allTargets: allTargets,
            oldVersionName: oldVersionName,
            newVersionName: newVersionName,
            warnings: warnings
        )
    }
}
