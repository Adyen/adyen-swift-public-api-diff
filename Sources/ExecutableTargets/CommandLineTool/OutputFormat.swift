//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation

import PADLogging
import PADOutputGenerator

/// The format the result of the analysis is written in
enum OutputFormat: String, CaseIterable {
    case markdown
    case json

    func generator() -> any OutputGenerating<String> {
        switch self {
        case .markdown:
            MarkdownOutputGenerator()
        case .json:
            JSONOutputGenerator(toolVersion: ToolVersion.current)
        }
    }
}

// MARK: - Shared command helpers

extension PublicApiDiff {

    /// Writes the output to `path` or - if there is none - to stdout
    static func deliver(_ output: String, to path: String?) throws {
        if let path {
            try FileManager.default.write(output, to: path)
        } else {
            // We're not using a logger here as we always want to have it printed if no output was specified
            print(output)
        }
    }

    /// Logs the error. In `json` mode it is rethrown to get a non-zero exit status
    ///
    /// The `markdown` mode keeps its (historic) exit status `0` on errors as the GitHub Action and existing scripts rely on it
    ///
    /// Covered by `OutputFormatExitStatusTests` - changing the `markdown` behaviour is a breaking change.
    static func handle(_ error: any Error, format: OutputFormat, logger: any Logging) throws {
        logger.log("💥 \(error.localizedDescription)", from: "Main")
        if format == .json {
            throw ExitCode.failure
        }
    }
}
