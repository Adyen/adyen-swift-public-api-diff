import Foundation

public protocol FileHandling {
    
    var currentDirectoryPath: String { get }
    
    func loadData(from path: String) throws -> Data
    
    func removeItem(atPath path: String) throws
    
    func contentsOfDirectory(atPath path: String) throws -> [String]
    
    func createDirectory(atPath path: String) throws
    
    func createFile(atPath path: String, contents data: Data) -> Bool
    
    func fileExists(atPath path: String) -> Bool
}
