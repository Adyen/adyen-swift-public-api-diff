//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation

import PADCore
import PADLogging

import PADOutputGenerator
import PADPackageFileAnalyzer
import PADSwiftInterfaceDiff
import PADSwiftInterfaceFileLocator

/// Command that analyzes the differences between an old and new project and produces a human readable output
struct FrameworkToOutputCommand: AsyncParsableCommand {

    static var configuration: CommandConfiguration = .init(commandName: "framework")

    /// The path to the new/updated xcframework
    @Option(help: "Specify the updated .framework to compare to")
    public var new: String

    /// The path to the old/reference xcframework
    @Option(help: "Specify the old .framework to compare to")
    public var old: String

    /// The name of the target/module to show in the output
    @Option(help: "The name of your target/module to show in the output")
    public var targetName: String

    @Option(help: "[Optional] Specify the type of .swiftinterface you want to compare (public/private)")
    public var swiftInterfaceType: SwiftInterfaceType = .public

    @Option(help: "[Optional] The name of your old version (e.g. v1.0 / main) to show in the output")
    public var oldVersionName: String?

    @Option(help: "[Optional] The name of your new version (e.g. v2.0 / develop) to show in the output")
    public var newVersionName: String?

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

        let logger = PublicApiDiff.logger(with: logLevel, logOutputFilePath: logOutput)

        do {
            // MARK: - Locating .swiftinterface files

            let swiftInterfaceFiles = try Self.locateSwiftInterfaceFiles(
                targetName: targetName,
                oldPath: old,
                newPath: new,
                swiftInterfaceType: swiftInterfaceType,
                logger: logger
            )

            // MARK: - Analyzing .swiftinterface files

            let swiftInterfaceChanges = try await Self.analyzeSwiftInterfaceFiles(
                swiftInterfaceFiles: swiftInterfaceFiles,
                logger: logger
            )

            // MARK: - Generate Output

            let generatedOutput = try Self.generateOutput(
                for: swiftInterfaceChanges,
                warnings: [],
                allTargets: [targetName],
                oldVersionName: oldVersionName,
                newVersionName: newVersionName
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

private extension FrameworkToOutputCommand {

    static func locateSwiftInterfaceFiles(
        targetName: String,
        oldPath: String,
        newPath: String,
        swiftInterfaceType: SwiftInterfaceType,
        logger: any Logging
    ) throws -> [SwiftInterfaceFile] {
        let locator = SwiftInterfaceFileLocator(logger: logger)

        let oldSwiftInterfaceFileUrl = try locator.locate(
            for: targetName,
            derivedDataPath: oldPath,
            type: swiftInterfaceType
        )
        let newSwiftInterfaceFileUrl = try locator.locate(
            for: targetName,
            derivedDataPath: newPath,
            type: swiftInterfaceType
        )

        return [.init(
            name: targetName,
            oldFilePath: oldSwiftInterfaceFileUrl.path(),
            newFilePath: newSwiftInterfaceFileUrl.path()
        )]
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
        allTargets: [String]?,
        oldVersionName: String?,
        newVersionName: String?
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
