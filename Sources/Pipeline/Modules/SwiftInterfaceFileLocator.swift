import Foundation

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
    
    func locate(for scheme: String, derivedDataPath: String, type: SwiftInterfaceType) throws -> URL {
        let schemeSwiftModuleName = "\(scheme).swiftmodule"
        
        let swiftModulePathsForScheme = shell.execute("cd '\(derivedDataPath)'; find . -type d -name '\(schemeSwiftModuleName)'")
            .components(separatedBy: .newlines)
            .map { URL(filePath: $0) }

        guard let swiftModulePath = swiftModulePathsForScheme.first?.path() else {
            throw FileHandlerError.pathDoesNotExist(path: "find . -type d -name '\(schemeSwiftModuleName)'") // TODO: Better error
        }
        
        let completeSwiftModulePath = derivedDataPath + "/" + swiftModulePath
        
        let swiftModuleContent = try fileHandler.contentsOfDirectory(atPath: completeSwiftModulePath)
        
        let swiftInterfacePaths: [String]
        switch type {
        case .private:
            swiftInterfacePaths = swiftModuleContent.filter { $0.hasSuffix(".private.swiftinterface") }
        case .public:
            swiftInterfacePaths = swiftModuleContent.filter { $0.hasSuffix(".swiftinterface") && !$0.hasSuffix(".private.swiftinterface") }
        }
        
        guard let swiftInterfacePath = swiftInterfacePaths.first else {
            switch type {
            case .private:
                throw FileHandlerError.pathDoesNotExist(path: "'\(scheme).private.swiftinterface'") // TODO: Better error
            case .public:
                throw FileHandlerError.pathDoesNotExist(path: "'\(scheme).swiftinterface'") // TODO: Better error
            }
        }
        
        return URL(filePath: "\(completeSwiftModulePath)/\(swiftInterfacePath)")
    }
}
