//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// A group of loggers
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
