import Foundation

public protocol Logging {
    
    func log(_ message: String, from subsystem: String)
    func debug(_ message: String, from subsystem: String)
}
