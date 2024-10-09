import Foundation
import OSLog

struct SystemLogger: Logging {
    
    private let logLevel: LogLevel
    
    init(logLevel: LogLevel) {
        self.logLevel = logLevel
    }
    
    func log(_ message: String, from subsystem: String) {
        guard logLevel.shouldLog else { return }
        logger(for: subsystem).log("\(message)")
    }
    
    func debug(_ message: String, from subsystem: String) {
        guard logLevel.shouldDebugLog else { return }
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
