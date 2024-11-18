//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

internal extension ProjectSource {
    enum Error: LocalizedError, Equatable {
        case invalidSourceValue(value: String)
        
        var errorDescription: String? {
            switch self {
            case let .invalidSourceValue(value):
                "Invalid source parameter `\(value)`. It needs to either be a local file path or a repository in the format `[BRANCH_OR_TAG]\(ProjectSource.gitSourceSeparator)[REPOSITORY_URL]"
            }
        }
    }
}
