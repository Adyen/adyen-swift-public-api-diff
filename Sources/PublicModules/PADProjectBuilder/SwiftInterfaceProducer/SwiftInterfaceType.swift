import Foundation

/// The type of the .swiftinterface to parse/generate
public enum PADSwiftInterfaceType {
    case `private`
    case `public`
    
    var name: String {
        switch self {
        case .private: "private"
        case .public: "public"
        }
    }
}
