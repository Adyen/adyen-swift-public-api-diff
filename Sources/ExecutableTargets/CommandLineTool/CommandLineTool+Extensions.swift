//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser

import PADLogging
import PADSwiftInterfaceFileLocator

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
