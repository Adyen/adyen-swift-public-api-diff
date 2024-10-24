//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

extension FileManager: FileHandling {

    package func createDirectory(atPath path: String) throws {
        try createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    package func createFile(atPath path: String, contents data: Data) -> Bool {
        createFile(atPath: path, contents: data, attributes: nil)
    }
    
    package func loadData(from filePath: String) throws -> Data {
        guard let data = self.contents(atPath: filePath) else {
            throw FileHandlerError.couldNotLoadFile(filePath: filePath)
        }
        
        return data
    }
    
    package func fileIsDirectory(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
        return isDirectory.boolValue
    }
    
    package func fileSize(atPath path: String) -> Int {
        guard
            let attributes = try? attributesOfItem(atPath: path),
            let fileSizeInBytes = attributes[FileAttributeKey.size] as? Int
        else {
            return 0
        }
        
        return fileSizeInBytes
    }
}
