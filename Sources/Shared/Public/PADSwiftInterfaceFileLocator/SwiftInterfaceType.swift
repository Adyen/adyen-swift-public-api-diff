//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

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
