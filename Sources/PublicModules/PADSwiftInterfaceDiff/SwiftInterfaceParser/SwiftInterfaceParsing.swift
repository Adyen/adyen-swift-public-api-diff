//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

protocol SwiftInterfaceParsing {
    func parse(source: String, moduleName: String) -> any SwiftInterfaceElement
    func parse(source: String, moduleName: String, apiScope: APIScope) -> any SwiftInterfaceElement
}

extension SwiftInterfaceParsing {

    func parse(source: String, moduleName: String, apiScope: APIScope) -> any SwiftInterfaceElement {
        parse(source: source, moduleName: moduleName)
    }
}
