import Foundation

/// Specifying the logger interface
public protocol PADLogging {
    /// Logs a message marked as `log`
    func log(_ message: String, from subsystem: String)
    /// Logs a message marked as `debug`
    func debug(_ message: String, from subsystem: String)
}
