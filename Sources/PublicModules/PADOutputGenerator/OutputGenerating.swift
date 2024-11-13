//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

/// Interface definition for an output generator
public protocol OutputGenerating<OutputType> {

    associatedtype OutputType

    /// Generates an output from input parameters
    /// - Parameters:
    ///   - changesPerTarget: A list of changes per target/module
    ///   - allTargets: A list of all targets/modules that were analysed in previous steps
    ///   - oldVersionName: The name of the old/reference version
    ///   - newVersionName: The name of the new/updated version
    ///   - warnings: A list of warnings produced in previous steps
    /// - Returns: An output of type ``OutputType``
    func generate(
        from changesPerTarget: [String: [Change]],
        allTargets: [String]?,
        oldVersionName: String?,
        newVersionName: String?,
        warnings: [String]
    ) throws -> OutputType
}
