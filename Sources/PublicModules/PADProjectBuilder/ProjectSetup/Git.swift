import Foundation

import PADCore
import PADLogging

import FileHandlingModule
import ShellModule

internal enum GitError: LocalizedError, Equatable {
    case couldNotClone(branchOrTag: String, repository: String)
    
    var errorDescription: String? {
        switch self {
        case let .couldNotClone(branchOrTag, repository):
            "Could not clone \(repository) @ \(branchOrTag) - Please check the provided information"
        }
    }
}

internal struct Git {
    
    private let shell: ShellHandling
    private let fileHandler: FileHandling
    private let logger: Logging?
    
    init(
        shell: ShellHandling,
        fileHandler: FileHandling,
        logger: Logging?
    ) {
        self.shell = shell
        self.fileHandler = fileHandler
        self.logger = logger
    }
    
    /// Clones a repository at a specific branch or tag into the current directory
    ///
    /// - Parameters:
    ///   - repository: The repository to clone
    ///   - branchOrTag: The branch or tag to clone
    ///   - targetDirectoryPath: The directory to clone into
    ///
    /// - Returns: The local directory path where to find the cloned repository
    func clone(_ repository: String, at branchOrTag: String, targetDirectoryPath: String) throws {
        logger?.log("🐱 Cloning \(repository) @ \(branchOrTag) into \(targetDirectoryPath)", from: String(describing: Self.self))
        let command = "git clone -b \(branchOrTag) \(repository) \(targetDirectoryPath)"
        
        let shellOutput = shell.execute(command)
        logger?.debug(shellOutput, from: String(describing: Self.self))
        
        let directoryContents = try fileHandler.contentsOfDirectory(atPath: targetDirectoryPath)
        guard !directoryContents.isEmpty else {
            throw GitError.couldNotClone(branchOrTag: branchOrTag, repository: repository)
        }
    }
}
