//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Specifying the logger interface
public protocol Logging {
    /// Logs a message marked as `log`
    func log(_ message: String, from subsystem: String)
    /// Logs a message marked as `debug`
    func debug(_ message: String, from subsystem: String)
}
