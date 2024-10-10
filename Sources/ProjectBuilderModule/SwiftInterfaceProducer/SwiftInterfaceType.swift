import Foundation
import ArgumentParser

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

extension SwiftInterfaceType: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "private": self = .private
        case "public": self = .public
        default: return nil
        }
    }
}
