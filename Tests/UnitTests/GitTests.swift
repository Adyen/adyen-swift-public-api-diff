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
        
        let shellExpectation = expectation(description: "MockShell.execute was called once")
        let fileHandlerExpectation = expectation(description: "MockFileHandler.handleContentsOfDirectory was called once")
        let loggerLogExpectation = expectation(description: "MockLogger.handleLog was called once")
        let loggerDebugExpectation = expectation(description: "MockLogger.handleDebug was called once")
        let allExpectations = [shellExpectation, fileHandlerExpectation, loggerLogExpectation, loggerDebugExpectation]
        
        let mockShell = MockShell { command in
            XCTAssertEqual(command, "git clone -b \(branch) \(repository) \(targetDirectoryPath)")
            shellExpectation.fulfill()
            return shellResult
        }
        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { directoryPath in
            XCTAssertEqual(targetDirectoryPath, directoryPath)
            fileHandlerExpectation.fulfill()
            return ["NonEmpty"]
        }
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
        
        let git = Git(shell: mockShell, fileHandler: mockFileHandler, logger: mockLogger)
        try git.clone(repository, at: branch, targetDirectoryPath: targetDirectoryPath)
        
        wait(for: allExpectations, timeout: 1)
    }
    
    func test_clone_fail() throws {
        
        let repository = "repository"
        let branch = "branch"
        let targetDirectoryPath = "targetDirectoryPath"
        let shellResult = "shell-result"
        
        let shellExpectation = expectation(description: "MockShell.execute was called once")
        let fileHandlerExpectation = expectation(description: "MockFileHandler.handleContentsOfDirectory was called once")
        let loggerLogExpectation = expectation(description: "MockLogger.handleLog was called once")
        let loggerDebugExpectation = expectation(description: "MockLogger.handleDebug was called once")
        let allExpectations = [shellExpectation, fileHandlerExpectation, loggerLogExpectation, loggerDebugExpectation]
        
        let mockShell = MockShell { command in
            XCTAssertEqual(command, "git clone -b \(branch) \(repository) \(targetDirectoryPath)")
            shellExpectation.fulfill()
            return shellResult
        }
        
        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { directoryPath in
            XCTAssertEqual(targetDirectoryPath, directoryPath)
            fileHandlerExpectation.fulfill()
            return []
        }
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
        
        let git = Git(shell: mockShell, fileHandler: mockFileHandler, logger: mockLogger)
        
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
