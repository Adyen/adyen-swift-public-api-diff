//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import FileHandlingModule
import PADCore
import PADLogging

/// Takes a list of ``PADCore/SwiftInterfaceFile``s and detects changes between the old and new version
public struct SwiftInterfaceDiff {
    
    public typealias ModuleName = String
    
    let fileHandler: any FileHandling
    let swiftInterfaceParser: any SwiftInterfaceParsing
    let swiftInterfaceAnalyzer: any SwiftInterfaceAnalyzing
    let logger: (any Logging)?
    
    /// Creates a new instance of ``SwiftInterfaceDiff``
    /// - Parameter logger: The (optional) logger
    public init(
        logger: (any Logging)? = nil
    ) {
        self.init(
            fileHandler: FileManager.default,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
            logger: logger
        )
    }
    
    init(
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
    
    /// Analyzes the passed ``PADCore/SwiftInterfaceFile``s and returns a list of changes grouped by scheme/target
    /// - Parameter swiftInterfaceFiles: The ``PADCore/SwiftInterfaceFile``s to analyze
    /// - Returns: A list of changes grouped by scheme/target
    public func run(with swiftInterfaceFiles: [SwiftInterfaceFile]) async throws -> [ModuleName: [Change]] {
        
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
