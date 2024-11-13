//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADSwiftInterfaceDiff
import XCTest

struct MockSwiftInterfaceParser: SwiftInterfaceParsing {

    var handleParseSource: (String, String) -> any SwiftInterfaceElement = { _, _ in
        XCTFail("Unexpectedly called `\(#function)`")
        return SwiftInterfaceParser.Root(moduleName: "Module Name", elements: [])
    }

    func parse(source: String, moduleName: String) -> any SwiftInterfaceElement {
        handleParseSource(source, moduleName)
    }
}
