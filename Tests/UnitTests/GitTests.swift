//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import Testing

@Suite
struct GitTests {
    
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
