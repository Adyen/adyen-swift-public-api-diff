//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import XCTest

class GitTests: XCTestCase {
    
    func test_clone_success() throws {
        
        let repository = "repository"
        let branch = "branch"
        let targetDirectoryPath = "targetDirectoryPath"
        let shellResult = "shell-result"
        
        let shellSetup = setupShell(
            branch: branch,
            repository: repository,
            targetDirectoryPath: targetDirectoryPath,
            result: shellResult
        )
        
        let fileHandlerSetup = setupFileHandler(
            targetDirectoryPath: targetDirectoryPath,
            result: ["NonEmpty"]
        )
        
        let loggerSetup = setupLogger(
            shellResult: shellResult
        )
        
        let allExpectations = [shellSetup.expectation, fileHandlerSetup.expectation] + loggerSetup.expectations
        
        let git = Git(
            shell: shellSetup.shell,
            fileHandler: fileHandlerSetup.fileHandler,
            logger: loggerSetup.logger
        )
        
        try git.clone(repository, at: branch, targetDirectoryPath: targetDirectoryPath)
        
        wait(for: allExpectations, timeout: 1)
    }
    
    func test_clone_fail() throws {
        
        let repository = "repository"
        let branch = "branch"
        let targetDirectoryPath = "targetDirectoryPath"
        let shellResult = "shell-result"
        
        let shellSetup = setupShell(
            branch: branch,
            repository: repository,
            targetDirectoryPath: targetDirectoryPath,
            result: shellResult
        )
        
        let fileHandlerSetup = setupFileHandler(
            targetDirectoryPath: targetDirectoryPath,
            result: []
        )
        
        let loggerSetup = setupLogger(
            shellResult: shellResult
        )
        
        let allExpectations = [shellSetup.expectation, fileHandlerSetup.expectation] + loggerSetup.expectations
        
        let git = Git(
            shell: shellSetup.shell,
            fileHandler: fileHandlerSetup.fileHandler,
            logger: loggerSetup.logger
        )
        
        do {
            try git.clone(repository, at: branch, targetDirectoryPath: targetDirectoryPath)
            XCTFail("Clone should have thrown an error")
        } catch {
            let fileHandlerError = try XCTUnwrap(error as? GitError)
            XCTAssertEqual(fileHandlerError, GitError.couldNotClone(branchOrTag: branch, repository: repository))
        }
        
        wait(for: allExpectations, timeout: 1)
    }
}

private extension GitTests {
    
    func setupShell(
        branch: String,
        repository: String,
        targetDirectoryPath: String,
        result: String
    ) -> (shell: MockShell, expectation: XCTestExpectation) {
        
        let shellExpectation = expectation(description: "MockShell.execute was called once")
        
        let mockShell = MockShell { command in
            XCTAssertEqual(command, "git clone -b \(branch) \(repository) \(targetDirectoryPath)")
            shellExpectation.fulfill()
            return result
        }
        
        return (mockShell, shellExpectation)
    }
    
    func setupFileHandler(
        targetDirectoryPath: String,
        result: [String]
    ) -> (fileHandler: MockFileHandler, expectation: XCTestExpectation) {
        
        let fileHandlerExpectation = expectation(description: "MockFileHandler.handleContentsOfDirectory was called once")
        
        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { directoryPath in
            XCTAssertEqual(targetDirectoryPath, directoryPath)
            fileHandlerExpectation.fulfill()
            return result
        }
        return (mockFileHandler, fileHandlerExpectation)
    }
    
    func setupLogger(
        shellResult: String
    ) -> (logger: MockLogger, expectations: [XCTestExpectation]) {
        
        let loggerLogExpectation = expectation(description: "MockLogger.handleLog was called once")
        let loggerDebugExpectation = expectation(description: "MockLogger.handleDebug was called once")
        
        var mockLogger = MockLogger()
        mockLogger.handleLog = { message, subsystem in
            XCTAssertEqual(message, "🐱 Cloning repository @ branch into targetDirectoryPath")
            XCTAssertEqual(subsystem, "Git")
            loggerLogExpectation.fulfill()
        }
        mockLogger.handleDebug = { message, subsystem in
            XCTAssertEqual(message, shellResult)
            XCTAssertEqual(subsystem, "Git")
            loggerDebugExpectation.fulfill()
        }
        
        return (mockLogger, [loggerLogExpectation, loggerDebugExpectation])
    }
}
