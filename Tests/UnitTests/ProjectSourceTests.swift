//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import XCTest

class ProjectSourceTests: XCTestCase {
    
    // MARK: - Remote
    
    func test_remote_validSource() throws {
        let repositoryUrl = "https://github.com/Adyen/adyen-ios.git"
        let separator = PADProjectSource.gitSourceSeparator
        let branch = "develop"
        let rawProjectSourceValue = "\(branch)\(separator)\(repositoryUrl)"
        
        let mockFileHandler = MockFileHandler(handleFileExists: {
            XCTAssertEqual($0, rawProjectSourceValue)
            return false
        })
        
        let projectSource = try PADProjectSource.from(
            "\(branch)\(separator)\(repositoryUrl)",
            fileHandler: mockFileHandler
        )
        
        XCTAssertEqual(
            projectSource,
            .git(branch: branch, repository: repositoryUrl)
        )
    }
    
    func test_remote_invalidRepoUrl() throws {
        let repositoryUrl = ""
        let separator = PADProjectSource.gitSourceSeparator
        let branch = "develop"
        let rawProjectSourceValue = "\(branch)\(separator)\(repositoryUrl)"
        
        let mockFileHandler = MockFileHandler(handleFileExists: {
            XCTAssertEqual($0, rawProjectSourceValue)
            return false
        })
        
        do {
            let source = try PADProjectSource.from(
                rawProjectSourceValue,
                fileHandler: mockFileHandler
            )
            XCTAssertNil(source) // Guard to make sure that we catch if it succeeds
        } catch {
            let projectSourceError = try XCTUnwrap(error as? PADProjectSource.Error)
            
            XCTAssertEqual(
                projectSourceError,
                PADProjectSource.Error.invalidSourceValue(value: rawProjectSourceValue)
            )
        }
    }
    
    func test_remote_invalidSeparator() throws {
        let repositoryUrl = "https://github.com/Adyen/adyen-ios.git"
        let separator = "_"
        let branch = "develop"
        let rawProjectSourceValue = "\(branch)\(separator)\(repositoryUrl)"
        
        let mockFileHandler = MockFileHandler(handleFileExists: {
            XCTAssertEqual($0, rawProjectSourceValue)
            return false
        })
        
        do {
            let source = try PADProjectSource.from(
                rawProjectSourceValue,
                fileHandler: mockFileHandler
            )
            XCTAssertNil(source) // Guard to make sure that we catch if it succeeds
        } catch {
            let projectSourceError = try XCTUnwrap(error as? PADProjectSource.Error)
            
            XCTAssertEqual(
                projectSourceError,
                PADProjectSource.Error.invalidSourceValue(value: rawProjectSourceValue)
            )
        }
    }
    
    // MARK: - Local
    
    func test_local_validSource() throws {
        let repositoryDirectoryPath = "/Some/Repository/Directory"
        let mockFileHandler = MockFileHandler(handleFileExists: {
            XCTAssertEqual($0, repositoryDirectoryPath)
            return true
        })
        
        let projectSource = try PADProjectSource.from(
            repositoryDirectoryPath,
            fileHandler: mockFileHandler
        )
        
        XCTAssertEqual(
            projectSource,
            .local(path: repositoryDirectoryPath)
        )
    }
    
    func test_local_nonExistentDirectory() throws {
        let repositoryDirectoryPath = "/Some/Repository/Directory"
        let mockFileHandler = MockFileHandler(handleFileExists: {
            XCTAssertEqual($0, repositoryDirectoryPath)
            return false
        })
        
        let projectSource = try? PADProjectSource.from(
            repositoryDirectoryPath,
            fileHandler: mockFileHandler
        )
        
        XCTAssertNil(projectSource)
    }
}
