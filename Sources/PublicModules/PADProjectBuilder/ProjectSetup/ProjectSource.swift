//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import FileHandlingModule

enum ProjectSourceError: LocalizedError, Equatable {
    case invalidSourceValue(value: String)
    
    var errorDescription: String? {
        switch self {
        case let .invalidSourceValue(value):
            "Invalid source parameter `\(value)`. It needs to either be a local file path or a repository in the format `[BRANCH_OR_TAG]\(PADProjectSource.gitSourceSeparator)[REPOSITORY_URL]"
        }
    }
}

public enum PADProjectSource: Equatable, CustomStringConvertible {
    
    /// The separator used to join branch & repository
    static var gitSourceSeparator: String { "~" }
    
    case local(path: String)
    case remote(branch: String, repository: String)
 
    public static func from(_ rawValue: String) throws -> Self {
        try from(rawValue, fileHandler: FileManager.default)
    }
    
    package static func from(_ rawValue: String, fileHandler: FileHandling) throws -> Self {
        if fileHandler.fileExists(atPath: rawValue) {
            return .local(path: rawValue)
        }
        
        let remoteComponents = rawValue.components(separatedBy: gitSourceSeparator)
        if remoteComponents.count == 2, let branch = remoteComponents.first, let repository = remoteComponents.last, URL(string: repository) != nil {
            return .remote(branch: branch, repository: repository)
        }
        
        throw ProjectSourceError.invalidSourceValue(value: rawValue)
    }
    
    public var description: String {
        switch self {
        case let .local(path):
            return path
        case let .remote(branch, repository):
            return "\(repository) @ \(branch)"
        }
    }
}