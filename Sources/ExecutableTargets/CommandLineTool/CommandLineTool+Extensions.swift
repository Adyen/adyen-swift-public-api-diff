import ArgumentParser

import PADProjectBuilder
import PADLogging

extension SwiftInterfaceType: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "public": self = .public
        case "private": self = .private
        default: return nil
        }
    }
}

extension LogLevel: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument {
        case "quiet": self = .quiet
        case "default": self = .default
        case "debug": self = .debug
        default: return nil
        }
    }
}
