import Foundation

enum LogLevel {
    /// No logs
    case quiet
    /// All logs except `debug`
    case `default`
    /// All logs
    case debug
    
    var shouldLog: Bool {
        switch self {
        case .quiet:
            return false
        case .default:
            return true
        case .debug:
            return true
        }
    }
    
    var shouldDebugLog: Bool {
        switch self {
        case .quiet:
            return false
        case .default:
            return false
        case .debug:
            return true
        }
    }
}
