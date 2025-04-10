//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import XCTest

struct MockRandomStringGenerator: RandomStringGenerating {

    var onGenerateRandomString: () -> String = {
        XCTFail("Unexpectedly called `\(#function)`")
        return ""
    }

    func generateRandomString() -> String {
        onGenerateRandomString()
    }
}
