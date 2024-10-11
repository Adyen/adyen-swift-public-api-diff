//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADOutputGenerator
@testable import PADCore
import XCTest

struct MockOutputGenerator: PADOutputGenerating {

    var onGenerate: ([String: [PADChange]], [String], String, String, [String]) throws -> String
    
    func generate(
        from changesPerTarget: [String: [PADChange]],
        allTargets: [String],
        oldVersionName: String,
        newVersionName: String,
        warnings: [String]
    ) throws -> String {
        try onGenerate(changesPerTarget, allTargets, oldVersionName, newVersionName, warnings)
    }
}
