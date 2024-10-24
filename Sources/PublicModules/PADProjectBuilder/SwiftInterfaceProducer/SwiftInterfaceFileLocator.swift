import Foundation

import FileHandlingModule
import ShellModule
import PADLogging

/// A helper to locate `.swiftinterface` files
struct SwiftInterfaceFileLocator {
    
    let fileHandler: any FileHandling
    let shell: any ShellHandling
    let logger: (any Logging)?
    
    init(
        fileHandler: any FileHandling = FileManager.default,
        shell: any ShellHandling = Shell(),
        logger: (any Logging)?
    ) {
        self.fileHandler = fileHandler
        self.shell = shell
        self.logger = logger
    }
    
    
    /// Tries to locate a `.swiftinterface` files in the derivedData folder for a specific scheme
    /// - Parameters:
    ///   - scheme: The scheme to find the `.swiftinterface` file for
    ///   - derivedDataPath: The path to the derived data directory (e.g. .../.build)
    ///   - type: The swift interface type (.public, .private) to look for
    /// - Returns: The file url to the found `.swiftinterface`
    /// - Throws: An error if no `.swiftinterface` file can be found for the given scheme + derived data path
    func locate(for scheme: String, derivedDataPath: String, type: SwiftInterfaceType) throws -> URL {
        let schemeSwiftModuleName = "\(scheme).swiftmodule"
        
        let swiftModulePathsForScheme = shell.execute("cd '\(derivedDataPath)'; find . -type d -name '\(schemeSwiftModuleName)'")
            .components(separatedBy: .newlines)
            .map { URL(filePath: $0) }

        guard let swiftModulePath = swiftModulePathsForScheme.first?.path() else {
            throw FileHandlerError.pathDoesNotExist(path: "find . -type d -name '\(schemeSwiftModuleName)'")
        }
        
        let completeSwiftModulePath = derivedDataPath + "/" + swiftModulePath
        
        let swiftModuleContent = try fileHandler.contentsOfDirectory(atPath: completeSwiftModulePath)
        
        let swiftInterfaceExtension = ".swiftinterface"
        let privateSwiftInterfaceExtension = ".private.swiftinterface"
        
        let swiftInterfacePaths: [String]
        switch type {
        case .private:
            swiftInterfacePaths = swiftModuleContent.filter { $0.hasSuffix(privateSwiftInterfaceExtension) }
        case .public:
            swiftInterfacePaths = swiftModuleContent.filter { $0.hasSuffix(swiftInterfaceExtension) && !$0.hasSuffix(privateSwiftInterfaceExtension) }
        }
        
        guard let swiftInterfacePath = swiftInterfacePaths.first else {
            switch type {
            case .private:
                throw FileHandlerError.pathDoesNotExist(path: "'\(completeSwiftModulePath)/\(scheme)\(privateSwiftInterfaceExtension)'")
            case .public:
                throw FileHandlerError.pathDoesNotExist(path: "'\(completeSwiftModulePath)/\(scheme)\(swiftInterfaceExtension)'")
            }
        }
        
        return URL(filePath: "\(completeSwiftModulePath)/\(swiftInterfacePath)")
    }
}
