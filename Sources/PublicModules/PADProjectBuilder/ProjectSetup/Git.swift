//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import PADCore
import PADLogging

import FileHandlingModule
import ShellModule

internal enum GitError: LocalizedError, Equatable {
    case couldNotClone(branchOrTag: String, repository: String)
    case mergeConflict(branch: String)

    var errorDescription: String? {
        switch self {
        case let .couldNotClone(branchOrTag, repository):
            "Could not clone \(repository) @ \(branchOrTag) - Please check the debug logs for more information"
        case let .mergeConflict(branch):
            "The compared branches have conflicting changes. This comparison may be inaccurate — please update your branch with the latest changes from `\(branch)` and re-run."
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

    /// Merges a branch from a repository into an already-cloned directory.
    ///
    /// This is used to avoid misleading diff output when the source branch is out of date
    /// with the target branch: by merging the target into the source first, the diff only
    /// reflects the source branch's actual changes.
    ///
    /// - Parameters:
    ///   - branch: The branch to merge
    ///   - repository: The repository the branch lives in
    ///   - clonedDirectoryPath: The local directory of the already-cloned source
    ///
    /// - Throws: ``GitError/mergeConflict(branch:)`` if the merge produces conflicts
    func merge(_ branch: String, from repository: String, into clonedDirectoryPath: String) throws {
        logger?.log("🔀 Merging \(repository) @ \(branch) into \(clonedDirectoryPath)", from: String(describing: Self.self))

        let fetchOutput = shell.execute("git -C '\(clonedDirectoryPath)' fetch origin \(branch)")
        logger?.debug(fetchOutput, from: String(describing: Self.self))

        let mergeOutput = shell.execute("git -C '\(clonedDirectoryPath)' merge origin/\(branch) --no-edit")
        logger?.debug(mergeOutput, from: String(describing: Self.self))

        if fileHandler.fileExists(atPath: "\(clonedDirectoryPath)/.git/MERGE_HEAD") {
            shell.execute("git -C '\(clonedDirectoryPath)' merge --abort")
            throw GitError.mergeConflict(branch: branch)
        }
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
        
        let directoryContents = try? fileHandler.contentsOfDirectory(atPath: targetDirectoryPath)
        guard let directoryContents, !directoryContents.isEmpty else {
            throw GitError.couldNotClone(branchOrTag: branchOrTag, repository: repository)
        }
    }
}
