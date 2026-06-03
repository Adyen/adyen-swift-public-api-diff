//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import Testing

@Suite
struct GitTests {

    @Test func mergeSuccess() throws {

        let branch = "branch"
        let repository = "repository"
        let clonedDirectoryPath = "clonedDirectoryPath"
        let fetchOutput = "fetch-output"
        let mergeOutput = "merge-output"

        let (shell, logger, fileHandler) = setupMerge(
            branch: branch,
            repository: repository,
            clonedDirectoryPath: clonedDirectoryPath,
            fetchOutput: fetchOutput,
            mergeOutput: mergeOutput,
            mergeHeadExists: false
        )

        let git = Git(shell: shell, fileHandler: fileHandler, logger: logger)
        try git.merge(branch, from: repository, into: clonedDirectoryPath)
    }

    @Test func mergeFail() throws {

        let branch = "branch"
        let repository = "repository"
        let clonedDirectoryPath = "clonedDirectoryPath"

        let (shell, logger, fileHandler) = setupMerge(
            branch: branch,
            repository: repository,
            clonedDirectoryPath: clonedDirectoryPath,
            fetchOutput: "",
            mergeOutput: "",
            mergeHeadExists: true
        )

        let git = Git(shell: shell, fileHandler: fileHandler, logger: logger)

        let expectedError = GitError.mergeConflict(branch: branch)
        #expect(throws: expectedError) {
            try git.merge(branch, from: repository, into: clonedDirectoryPath)
        }
        #expect(expectedError.localizedDescription == "The compared branches have conflicting changes. This comparison may be inaccurate — please update your branch with the latest changes from `\(branch)` and re-run.")
    }

    @Test func cloneSuccess() throws {
        
        let repository = "repository"
        let branch = "branch"
        let targetDirectoryPath = "targetDirectoryPath"
        let shellResult = "shell-result"
        
        let shell = setupShell(
            branch: branch,
            repository: repository,
            targetDirectoryPath: targetDirectoryPath,
            result: shellResult
        )
        
        let fileHandler = setupFileHandler(
            targetDirectoryPath: targetDirectoryPath,
            result: ["NonEmpty"]
        )
        
        let logger = setupLogger(
            shellResult: shellResult
        )
        
        let git = Git(
            shell: shell,
            fileHandler: fileHandler,
            logger: logger
        )
        
        try git.clone(repository, at: branch, targetDirectoryPath: targetDirectoryPath)
    }
    
    @Test func cloneFail() throws {
        
        let repository = "repository"
        let branch = "branch"
        let targetDirectoryPath = "targetDirectoryPath"
        let shellResult = "shell-result"
        
        let shell = setupShell(
            branch: branch,
            repository: repository,
            targetDirectoryPath: targetDirectoryPath,
            result: shellResult
        )
        
        let fileHandler = setupFileHandler(
            targetDirectoryPath: targetDirectoryPath,
            result: []
        )
        
        let logger = setupLogger(
            shellResult: shellResult
        )
        
        let git = Git(
            shell: shell,
            fileHandler: fileHandler,
            logger: logger
        )
        
        #expect(throws: GitError.couldNotClone(branchOrTag: branch, repository: repository)) {
            try git.clone(repository, at: branch, targetDirectoryPath: targetDirectoryPath)
        }
    }
}

private extension GitTests {

    func setupMerge(
        branch: String,
        repository: String,
        clonedDirectoryPath: String,
        fetchOutput: String,
        mergeOutput: String,
        mergeHeadExists: Bool
    ) -> (MockShell, MockLogger, MockFileHandler) {

        var callCount = 0
        var expectedCommands = [
            "git -C '\(clonedDirectoryPath)' fetch origin \(branch)",
            "git -C '\(clonedDirectoryPath)' merge origin/\(branch) --no-edit"
        ]
        var expectedOutputs = [fetchOutput, mergeOutput]
        if mergeHeadExists {
            expectedCommands.append("git -C '\(clonedDirectoryPath)' merge --abort")
            expectedOutputs.append("")
        }

        let shell = MockShell { command in
            let index = callCount
            callCount += 1
            if index < expectedCommands.count {
                #expect(command == expectedCommands[index])
                return expectedOutputs[index]
            }
            return ""
        }

        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { path in
            #expect(path == "\(clonedDirectoryPath)/.git/MERGE_HEAD")
            return mergeHeadExists
        }

        var debugCallCount = 0
        let expectedDebugOutputs = [fetchOutput, mergeOutput]

        var logger = MockLogger()
        logger.handleLog = { message, subsystem in
            #expect(message == "🔀 Merging \(repository) @ \(branch) into \(clonedDirectoryPath)")
            #expect(subsystem == "Git")
        }
        logger.handleDebug = { message, subsystem in
            let index = debugCallCount
            debugCallCount += 1
            if index < expectedDebugOutputs.count {
                #expect(message == expectedDebugOutputs[index])
            }
            #expect(subsystem == "Git")
        }

        return (shell, logger, fileHandler)
    }

    func setupShell(
        branch: String,
        repository: String,
        targetDirectoryPath: String,
        result: String
    ) -> MockShell {
        
        MockShell { command in
            #expect(command == "git clone -b \(branch) \(repository) \(targetDirectoryPath)")
            return result
        }
    }
    
    func setupFileHandler(
        targetDirectoryPath: String,
        result: [String]
    ) -> MockFileHandler {
        
        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { directoryPath in
            #expect(targetDirectoryPath == directoryPath)
            return result
        }
        return mockFileHandler
    }
    
    func setupLogger(
        shellResult: String
    ) -> MockLogger {
        
        var mockLogger = MockLogger()
        mockLogger.handleLog = { message, subsystem in
            #expect(message == "🐱 Cloning repository @ branch into targetDirectoryPath")
            #expect(subsystem == "Git")
        }
        mockLogger.handleDebug = { message, subsystem in
            #expect(message == shellResult)
            #expect(subsystem == "Git")
        }
        
        return mockLogger
    }
}
