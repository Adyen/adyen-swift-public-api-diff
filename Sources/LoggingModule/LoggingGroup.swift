import Foundation
import CoreModule

public struct LoggingGroup: Logging {
    
    let logger: [any Logging]
    
    public init(with logger: [any Logging]) {
        self.logger = logger
    }
    
    public func log(_ message: String, from subsystem: String) {
        logger.forEach { $0.log(message, from: subsystem) }
    }
    
    public func debug(_ message: String, from subsystem: String) {
        logger.forEach { $0.debug(message, from: subsystem) }
    }
}
