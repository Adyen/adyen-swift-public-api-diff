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

extension SwiftInterfaceType: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "public": self = .public
        case "private": self = .private
        default: return nil
        }
    }
}

extension LogLevel: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "quiet": self = .quiet
        case "default": self = .default
        case "debug": self = .debug
        default: return nil
        }
    }
}

@main
struct PublicApiDiff: AsyncParsableCommand {
    
    static var configuration: CommandConfiguration = .init(
        subcommands: [
            ProjectToOutputCommand.self,
            SwiftInterfaceToOutputCommand.self
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
