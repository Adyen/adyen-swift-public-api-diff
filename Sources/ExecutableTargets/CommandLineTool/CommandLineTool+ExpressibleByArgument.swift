//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser

import PADLogging
import PADSwiftInterfaceFileLocator
import PADProjectBuilder

extension SwiftInterfaceType: ExpressibleByArgument {
    public init?(argument: String) {
        let mapping: [String: Self] = [
            "public": .package,
            "private": .private,
            "package": .package
        ]
        
        if let match = mapping.value(forArgument: argument) {
            self = match
        } else {
            return nil
        }
    }
}

extension LogLevel: ExpressibleByArgument {
    public init?(argument: String) {
        let mapping: [String: Self] = [
            "quiet": .quiet,
            "default": .default,
            "debug": .debug
        ]
        
        if let match = mapping.value(forArgument: argument) {
            self = match
        } else {
            return nil
        }
    }
}

extension ProjectPlatform: ExpressibleByArgument {
    public init?(argument: String) {
        let mapping: [String: Self] = [
            "iOS": .iOS,
            "macOS": .macOS
        ]
        
        if let match = mapping.value(forArgument: argument) {
            self = match
        } else {
            return nil
        }
    }
}

// MARK: - Convenience

fileprivate extension Dictionary where Key == String {
    func value(forArgument argument: String) -> Value? {
        for (key, value) in self {
            if argument.caseInsensitiveEquals(key) {
                return value
            }
        }
        
        return nil
    }
}

fileprivate extension String {
    func caseInsensitiveEquals(_ other: String) -> Bool {
        self.compare(other, options: .caseInsensitive) == .orderedSame
    }
}
