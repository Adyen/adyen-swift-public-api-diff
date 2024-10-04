import Foundation

struct SwiftInterfaceFileLocator {
    
    enum SwiftInterfaceType {
        case `private`
        case `public`
    }
    
    let fileHandler: any FileHandling
    let shell: any ShellHandling
    
    init(
        fileHandler: any FileHandling = FileManager.default,
        shell: any ShellHandling = Shell()
    ) {
        self.fileHandler = fileHandler
        self.shell = shell
    }
    
    func locate(for scheme: String, derivedDataPath: String, type: SwiftInterfaceType) throws -> [URL] {
        let swiftModulePaths = shell.execute("cd '\(derivedDataPath)'; find . -type d -name '\(scheme).swiftmodule'")
            .components(separatedBy: .newlines)
            .map { URL(filePath: $0) }

        guard let swiftModulePath = swiftModulePaths.first?.path() else {
            throw FileHandlerError.pathDoesNotExist(path: "find . -type d -name '\(scheme).swiftmodule'")
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
        
        return swiftInterfacePaths.map { URL(filePath: "\(completeSwiftModulePath)/\($0)") }
    }
}
