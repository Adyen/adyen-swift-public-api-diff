//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 08/10/2024.
//

import Foundation

struct LoggingGroup: Logging {
    
    let logger: [any Logging]
    
    init(with logger: [any Logging]) {
        self.logger = logger
    }
    
    @MainActor
    func log(_ message: String, from subsystem: String) {
        logger.forEach { $0.log(message, from: subsystem) }
    }
    
    @MainActor
    func debug(_ message: String, from subsystem: String) {
        logger.forEach { $0.debug(message, from: subsystem) }
    }
}
