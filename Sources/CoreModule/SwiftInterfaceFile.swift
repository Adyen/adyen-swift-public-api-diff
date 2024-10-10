import Foundation

public struct SwiftInterfaceFile {
    public let name: String
    public let oldFilePath: String
    public let newFilePath: String
    
    public init(name: String, oldFilePath: String, newFilePath: String) {
        self.name = name
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
    }
}
