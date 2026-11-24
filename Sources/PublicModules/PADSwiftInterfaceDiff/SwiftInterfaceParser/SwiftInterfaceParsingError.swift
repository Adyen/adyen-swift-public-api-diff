//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// An interface file contains syntax errors (e.g. it is truncated or was produced by an unsupported compiler)
///
/// Comparing such a file would silently drop or misinterpret declarations, so no report is produced.
public struct SwiftInterfaceParsingError: LocalizedError, Equatable {

    /// The path of the interface file, if known
    public internal(set) var filePath: String?

    /// The syntax errors as `line:column: message`
    public let diagnostics: [String]

    static let maximumNumberOfListedDiagnostics = 10

    public var errorDescription: String? {
        let file = filePath.map { " `\($0)`" } ?? ""
        var lines = ["Could not parse the interface file\(file): found \(diagnostics.count) syntax error(s)"]
        lines += diagnostics.prefix(Self.maximumNumberOfListedDiagnostics).map { "- \($0)" }
        if diagnostics.count > Self.maximumNumberOfListedDiagnostics {
            lines.append("- ... and \(diagnostics.count - Self.maximumNumberOfListedDiagnostics) more")
        }
        return lines.joined(separator: "\n")
    }
}
