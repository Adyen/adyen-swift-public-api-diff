//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 11/10/2024.
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

