import Foundation

struct LoggingGroup: Logging {
    
    let logger: [any Logging]
    let logLevel: LogLevel
    
    init(with logger: [any Logging], logLevel: LogLevel) {
        self.logger = logger
        self.logLevel = logLevel
    }
    
    func log(_ message: String, from subsystem: String) {
        guard logLevel.shouldLog else { return }
        logger.forEach { $0.log(message, from: subsystem) }
    }
    
    func debug(_ message: String, from subsystem: String) {
        guard logLevel.shouldDebugLog else { return }
        logger.forEach { $0.debug(message, from: subsystem) }
    }
}
