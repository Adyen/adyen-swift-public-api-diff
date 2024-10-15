//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADSwiftInterfaceDiff
@testable import PADCore
import XCTest

struct MockSwiftInterfaceAnalyzer: SwiftInterfaceAnalyzing {
    
    var handleAnalyze: (any SwiftInterfaceElement, any SwiftInterfaceElement) -> [Change] = { _, _ in
        XCTFail("Unexpectedly called `\(#function)`")
        return []
    }
    
    func analyze(old: some SwiftInterfaceElement, new: some SwiftInterfaceElement) throws -> [Change] {
        handleAnalyze(old, new)
    }
}
