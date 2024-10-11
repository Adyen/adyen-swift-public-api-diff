//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

package protocol RandomStringGenerating {
    
    func generateRandomString() -> String
}

package struct RandomStringGenerator: RandomStringGenerating {
    
    package init() {}
    
    package func generateRandomString() -> String {
        UUID().uuidString
    }
}
