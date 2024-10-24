import Foundation

package protocol FileHandling {
    
    var currentDirectoryPath: String { get }
    
    func loadData(from path: String) throws -> Data
    
    func removeItem(atPath path: String) throws
    
    func contentsOfDirectory(atPath path: String) throws -> [String]
    
    /// Creates a directory at the specified path
    func createDirectory(atPath path: String) throws
    
    /// Creates a file at the specified path with the provided content
    func createFile(atPath path: String, contents data: Data) -> Bool
    
    /// Checks whether or not a file exists at the specified path
    func fileExists(atPath path: String) -> Bool
    
    /// Checks whether or not the path points to a directory
    func fileIsDirectory(atPath path: String) -> Bool
    
    /// Returns the file size in bytes
    ///
    /// If file does not exist or the attributes can't be read it returns 0
    func fileSize(atPath path: String) -> Int
}
