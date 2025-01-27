//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import OSLog

/// A log level specifying the granularity of the emitted logs
public enum LogLevel {
    /// No logs
    case quiet
    /// All logs except `debug`
    case `default`
    /// All logs
    case debug

    var shouldLog: Bool {
        switch self {
        case .quiet:
            return false
        case .default:
            return true
        case .debug:
            return true
        }
    }

    var shouldDebugLog: Bool {
        switch self {
        case .quiet:
            return false
        case .default:
            return false
        case .debug:
            return true
        }
    }
}

// MARK: - LogLevelLogger

/// Logger that respects a ``LogLevel``
public struct LogLevelLogger<LoggerType: Logging>: Logging {

    private let logLevel: LogLevel
    internal let wrappedLogger: LoggerType

    init(with logger: LoggerType, logLevel: LogLevel) {
        self.wrappedLogger = logger
        self.logLevel = logLevel
    }

    public func log(_ message: String, from subsystem: String) {
        guard logLevel.shouldLog else { return }
        wrappedLogger.log("\(message)", from: subsystem)
    }

    public func debug(_ message: String, from subsystem: String) {
        guard logLevel.shouldDebugLog else { return }
        wrappedLogger.debug("\(message)", from: subsystem)
    }
}

// MARK: - Logging Extension

extension Logging {
    /// Wraps a logger into a ``LogLevelLogger`` to make them respect the ``LogLevel``
    public func withLogLevel(_ logLevel: LogLevel) -> LogLevelLogger<Self> {
        .init(with: self, logLevel: logLevel)
    }
}
