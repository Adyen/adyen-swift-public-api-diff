//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// A representation of 2 versions of a `.swiftinterface` file
public struct SwiftInterfaceFile {
    /// The name of the target/scheme that is represented in the `.swiftinterface` file
    public let name: String
    /// The file path to the old/reference `.swiftinterface`
    public let oldFilePath: String
    /// The file path to the new/updated `.swiftinterface`
    public let newFilePath: String

    /// Creates a new instance of a ``SwiftInterfaceFile``
    public init(
        name: String,
        oldFilePath: String,
        newFilePath: String
    ) {
        self.name = name
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
    }
}
