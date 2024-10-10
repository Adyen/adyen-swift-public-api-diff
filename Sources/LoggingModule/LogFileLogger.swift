import Foundation
import CoreModule
import FileHandlingModule

public class LogFileLogger: Logging {
    
    private let fileHandler: any FileHandling
    private let outputFilePath: String
    
    @MainActor
    private var output: [String] = [] {
        didSet {
            try? fileHandler.write(output.joined(separator: "\n"), to: outputFilePath)
        }
    }
    
    public init(fileHandler: any FileHandling, outputFilePath: String) {
        self.fileHandler = fileHandler
        self.outputFilePath = outputFilePath
    }
    
    public func log(_ message: String, from subsystem: String) {
        Task { @MainActor in
            output += ["🪵 [\(subsystem)] \(message)\n"]
        }
    }
    
    public func debug(_ message: String, from subsystem: String) {
        Task { @MainActor in
            output += ["🐞 [\(subsystem)] \(message)\n"]
        }
    }
}
