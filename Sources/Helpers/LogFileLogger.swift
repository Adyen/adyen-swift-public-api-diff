//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 08/10/2024.
//

import Foundation

class LogFileLogger: Logging {
    
    private let fileHandler: any FileHandling
    private let outputFilePath: String
    
    @MainActor
    private var output: [String] = [] {
        didSet {
            try? fileHandler.write(output.joined(separator: "\n"), to: outputFilePath)
        }
    }
    
    init(fileHandler: any FileHandling, outputFilePath: String) {
        self.fileHandler = fileHandler
        self.outputFilePath = outputFilePath
    }
    
    func log(_ message: String, from subsystem: String) {
        Task { @MainActor in
            output += ["[\(subsystem)] \(message)\n"]
        }
    }
    
    func debug(_ message: String, from subsystem: String) {
        Task { @MainActor in
            output += ["[\(subsystem)] \(message)\n"]
        }
    }
}
