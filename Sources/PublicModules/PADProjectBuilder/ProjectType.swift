//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// The type of project to build
public enum ProjectType {

    /// The project is a `Package.swift`
    /// When using this project type all targets get built
    case swiftPackage

    /// The project is an Xcode project/workspace
    /// When using this project type the specified scheme get built
    case xcodeProject(scheme: String)
}
