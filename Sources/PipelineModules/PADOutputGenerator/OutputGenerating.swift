//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

public protocol PADOutputGenerating {
    func generate(
        from changesPerTarget: [String: [PADChange]],
        allTargets: [String],
        oldVersionName: String,
        newVersionName: String,
        warnings: [String]
    ) throws -> String
}
