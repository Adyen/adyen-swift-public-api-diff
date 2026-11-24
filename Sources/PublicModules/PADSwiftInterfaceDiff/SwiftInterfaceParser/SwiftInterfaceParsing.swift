//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

protocol SwiftInterfaceParsing {
    /// - Throws: ``SwiftInterfaceParsingError`` if the source contains syntax errors
    func parse(source: String, moduleName: String, apiScope: APIScope) throws -> any SwiftInterfaceElement
}
