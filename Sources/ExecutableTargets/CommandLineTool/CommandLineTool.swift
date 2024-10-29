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
import PADPackageFileAnalyzer

@main
struct PublicApiDiff: AsyncParsableCommand {
    
    static var configuration: CommandConfiguration = .init(
        commandName: "public-api-diff",
        subcommands: [
            ProjectToOutputCommand.self,
            SwiftInterfaceToOutputCommand.self,
            FrameworkToOutputCommand.self
        ]
    )
    
    public func run() async throws {
        fatalError("No sub command provided")
    }
}

extension PublicApiDiff {
    
    static func logger(
        with logLevel: LogLevel,
        logOutputFilePath: String?
    ) -> any Logging {
        var loggers = [any Logging]()
        if let logOutputFilePath {
            loggers += [LogFileLogger(outputFilePath: logOutputFilePath)]
        }
        loggers += [SystemLogger().withLogLevel(logLevel)]
        
        return LoggingGroup(with: loggers)
    }
}
