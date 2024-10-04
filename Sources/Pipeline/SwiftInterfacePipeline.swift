//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 03/10/2024.
//

import Foundation

struct SwiftInterfacePipeline {
    
    let swiftInterfaceFiles: [SwiftInterfaceFile]
    
    let fileHandler: any FileHandling
    let swiftInterfaceParser: any SwiftInterfaceParsing
    let swiftInterfaceAnalyzer: any SwiftInterfaceAnalyzing
    let logger: (any Logging)?
    
    struct SwiftInterfaceFile {
        let name: String
        let oldFilePath: String
        let newFilePath: String
    }
    
    init(
        swiftInterfaceFiles: [SwiftInterfaceFile],
        fileHandler: FileHandling,
        swiftInterfaceParser: any SwiftInterfaceParsing,
        swiftInterfaceAnalyzer: any SwiftInterfaceAnalyzing,
        logger: (any Logging)?
    ) {
        self.swiftInterfaceFiles = swiftInterfaceFiles
        self.fileHandler = fileHandler
        self.swiftInterfaceParser = swiftInterfaceParser
        self.swiftInterfaceAnalyzer = swiftInterfaceAnalyzer
        self.logger = logger
    }
    
    func run() async throws -> [String: [Change]] {
        
        var changes = [String: [Change]]()
        
        try swiftInterfaceFiles.forEach { file in
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
