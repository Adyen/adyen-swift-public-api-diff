import Foundation

struct LoggingGroup: Logging {
    
    let logger: [any Logging]
    
    init(with logger: [any Logging]) {
        self.logger = logger
    }
    
    func log(_ message: String, from subsystem: String) {
        logger.forEach { $0.log(message, from: subsystem) }
    }
    
    func debug(_ message: String, from subsystem: String) {
        logger.forEach { $0.debug(message, from: subsystem) }
    }
}
