//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

extension FileManager: FileHandling {
    
    /// Creates a directory at the specified path
    package func createDirectory(atPath path: String) throws {
        try createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    /// Creates a file at the specified path with the provided content
    package func createFile(atPath path: String, contents data: Data) -> Bool {
        createFile(atPath: path, contents: data, attributes: nil)
    }
    
    package func loadData(from filePath: String) throws -> Data {
        guard let data = self.contents(atPath: filePath) else {
            throw FileHandlerError.couldNotLoadFile(filePath: filePath)
        }
        
        return data
    }
}
