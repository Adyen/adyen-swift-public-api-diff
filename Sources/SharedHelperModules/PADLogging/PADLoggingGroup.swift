import Foundation

public struct PADLoggingGroup: PADLogging {
    
    let logger: [any PADLogging]
    
    public init(with logger: [any PADLogging]) {
        self.logger = logger
    }
    
    public func log(_ message: String, from subsystem: String) {
        logger.forEach { $0.log(message, from: subsystem) }
    }
    
    public func debug(_ message: String, from subsystem: String) {
        logger.forEach { $0.debug(message, from: subsystem) }
    }
}
