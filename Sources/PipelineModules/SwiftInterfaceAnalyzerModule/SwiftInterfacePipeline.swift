import Foundation

import CoreModule
import FileHandlingModule
import LoggingModule

/// Takes a list of ``SwiftInterfaceFile`` and detects changes between the old and new version
public struct SwiftInterfacePipeline {
    
    let fileHandler: any FileHandling
    let swiftInterfaceParser: any SwiftInterfaceParsing
    let swiftInterfaceAnalyzer: any SwiftInterfaceAnalyzing
    let logger: (any Logging)?
    
    public init(
        fileHandler: FileHandling = FileManager.default,
        swiftInterfaceParser: any SwiftInterfaceParsing = SwiftInterfaceParser(),
        swiftInterfaceAnalyzer: any SwiftInterfaceAnalyzing = SwiftInterfaceAnalyzer(),
        logger: (any Logging)? = nil
    ) {
        self.fileHandler = fileHandler
        self.swiftInterfaceParser = swiftInterfaceParser
        self.swiftInterfaceAnalyzer = swiftInterfaceAnalyzer
        self.logger = logger
    }
    
    public func run(with swiftInterfaceFiles: [SwiftInterfaceFile]) async throws -> [String: [Change]] {
        
        var changes = [String: [Change]]()
        
        try swiftInterfaceFiles.forEach { file in
            logger?.log("🧑‍🔬 Analyzing \(file.name)", from: String(describing: Self.self))
            let newContent = try fileHandler.loadString(from: file.newFilePath)
            let oldContent = try fileHandler.loadString(from: file.oldFilePath)
            let newParsed = swiftInterfaceParser.parse(source: newContent, moduleName: file.name)
            let oldParsed = swiftInterfaceParser.parse(source: oldContent, moduleName: file.name)
            
            let moduleChanges = try swiftInterfaceAnalyzer.analyze(
                old: oldParsed,
                new: newParsed
            )
            
            if !moduleChanges.isEmpty {
                changes[file.name] = moduleChanges
            }
        }
        
        return changes
    }
}
