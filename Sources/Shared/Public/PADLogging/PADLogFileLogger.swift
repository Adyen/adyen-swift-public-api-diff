import Foundation
import FileHandlingModule

/// Logs into a log file at a specified output path
public class PADLogFileLogger: PADLogging {
    
    private let fileHandler: any FileHandling
    private let outputFilePath: String
    
    @MainActor
    private var output: [String] = [] {
        didSet {
            try? fileHandler.write(output.joined(separator: "\n"), to: outputFilePath)
        }
    }
    
    /// Creates a new instance that targets the specified output path
    public convenience init(outputFilePath: String) {
        self.init(fileHandler: FileManager.default, outputFilePath: outputFilePath)
    }
    
    init(
        fileHandler: any FileHandling,
        outputFilePath: String
    ) {
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
