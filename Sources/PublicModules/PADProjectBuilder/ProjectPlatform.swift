//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

/// The platform to build the project on
public enum ProjectPlatform {

    case macOS
    case iOS
    
    /// The display name for the platform
    public var displayName: String {
        switch self {
        case .macOS: return "macOS"
        case .iOS: return "iOS"
        }
    }
}
