//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import FileHandlingModule

/// The source type of the project (local/remote)
public enum PADProjectSource: Equatable, CustomStringConvertible {
    
    /// The separator used to join branch & repository
    static var gitSourceSeparator: String { "~" }
    
    /// Representing a local `path`
    case local(path: String)
    /// Representing a `branch` of a **git** `repository`
    case git(branch: String, repository: String)
 
    /// Creates a ``PADProjectSource`` from a rawValue
    /// - Parameters:
    ///   - rawValue: The rawValue presentation of a ``PADProjectSource``
    /// - Returns: A valid ``PADProjectSource``
    /// - Throws: An error if the `rawValue` does not match a ``PADProjectSource`` representation
    public static func from(_ rawValue: String) throws -> Self {
        try from(rawValue, fileHandler: FileManager.default)
    }
    
    package static func from(_ rawValue: String, fileHandler: FileHandling) throws -> Self {
        if fileHandler.fileExists(atPath: rawValue) {
            return .local(path: rawValue)
        }
        
        let remoteComponents = rawValue.components(separatedBy: gitSourceSeparator)
        if remoteComponents.count == 2, let branch = remoteComponents.first, let repository = remoteComponents.last, URL(string: repository) != nil {
            return .git(branch: branch, repository: repository)
        }
        
        throw Error.invalidSourceValue(value: rawValue)
    }
    
    public var description: String {
        switch self {
        case let .local(path):
            return path
        case let .git(branch, repository):
            return "\(repository) @ \(branch)"
        }
    }
}
