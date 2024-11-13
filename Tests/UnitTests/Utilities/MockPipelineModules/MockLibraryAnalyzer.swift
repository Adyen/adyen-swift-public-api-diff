//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADPackageFileAnalyzer

import XCTest

struct MockSwiftPackageFileAnalyzer: SwiftPackageFileAnalyzing {

    var onAnalyze: (URL, URL) throws -> SwiftPackageFileAnalyzingResult

    func analyze(oldProjectUrl: URL, newProjectUrl: URL) throws -> SwiftPackageFileAnalyzingResult {
        try onAnalyze(oldProjectUrl, newProjectUrl)
    }
}
