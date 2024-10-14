import Foundation

/// The type of the .swiftinterface to parse/generate
public enum SwiftInterfaceType {
    case `private`
    case `public`
    
    var name: String {
        switch self {
        case .private: "private"
        case .public: "public"
        }
    }
}
