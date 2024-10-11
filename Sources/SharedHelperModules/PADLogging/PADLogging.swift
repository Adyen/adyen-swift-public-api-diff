import Foundation

public protocol PADLogging {
    
    func log(_ message: String, from subsystem: String)
    func debug(_ message: String, from subsystem: String)
}
