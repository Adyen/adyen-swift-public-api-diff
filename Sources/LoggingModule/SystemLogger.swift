import Foundation
import OSLog
import CoreModule

public struct SystemLogger: Logging {
    
    public init() {}
    
    public func log(_ message: String, from subsystem: String) {
        logger(for: subsystem).log("\(message)")
    }
    
    public func debug(_ message: String, from subsystem: String) {
        logger(for: subsystem).debug("\(message)")
    }
}

private extension SystemLogger {
    
    func logger(for subsystem: String) -> Logger {
        Logger(
            subsystem: subsystem,
            category: "" // TODO: Pass the description/tag so it can be differentiated
        )
    }
}
