//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

public protocol RandomStringGenerating {
    
    func generateRandomString() -> String
}

public struct RandomStringGenerator: RandomStringGenerating {
    
    public init() {}
    
    public func generateRandomString() -> String {
        UUID().uuidString
    }
}
