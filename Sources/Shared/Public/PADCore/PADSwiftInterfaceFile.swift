import Foundation

/// A representation of 2 versions of a `.swiftinterface` file
public struct PADSwiftInterfaceFile {
    /// The name of the target/scheme that is represented in the `.swiftinterface` file
    public let name: String
    /// The file path to the old/reference `.swiftinterface`
    public let oldFilePath: String
    /// The file path to the new/updated `.swiftinterface`
    public let newFilePath: String
    
    /// Creates a new instance of a ``PADSwiftInterfaceFile``
    public init(
        name: String,
        oldFilePath: String,
        newFilePath: String
    ) {
        self.name = name
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
    }
}
