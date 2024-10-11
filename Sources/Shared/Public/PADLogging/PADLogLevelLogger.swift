import Foundation
import OSLog

public enum PADLogLevel {
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
public struct PADLogLevelLogger<LoggerType: PADLogging>: PADLogging {
    
    private let logLevel: PADLogLevel
    internal let wrappedLogger: LoggerType
    
    init(with logger: LoggerType, logLevel: PADLogLevel) {
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

extension PADLogging {
    public func withLogLevel(_ logLevel: PADLogLevel) -> PADLogLevelLogger<Self> {
        .init(with: self, logLevel: logLevel)
    }
}