//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import LoggingModule
import XCTest

struct MockLogger: Logging {
    
    var handleLog: (String, String) -> Void = { _, _ in
        XCTFail("Unexpectedly called `\(#function)`")
    }
    
    var handleDebug: (String, String) -> Void = { _, _ in
        XCTFail("Unexpectedly called `\(#function)`")
    }
    
    func log(_ message: String, from subsystem: String) {
        handleLog(message, subsystem)
    }
    
    func debug(_ message: String, from subsystem: String) {
        handleDebug(message, subsystem)
    }
}
