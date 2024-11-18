//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

public enum SwiftInterfaceElementDeclType: String, CaseIterable {
    case root
    case `actor`
    case `associatedtype`
    case `class`
    case `enum`
    case enumCase
    case `extension`
    case `func`
    case `init`
    case `protocol`
    case `struct`
    case `subscript`
    case `typealias`
    case `var`
}
