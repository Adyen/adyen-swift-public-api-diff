//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADProjectBuilder
import Testing

@Suite
struct ProjectSourceTests {

    // MARK: - Remote

    @Test func remoteValidSource() throws {
        let repositoryUrl = "https://github.com/Adyen/adyen-ios.git"
        let separator = ProjectSource.gitSourceSeparator
        let branch = "develop"
        let rawProjectSourceValue = "\(branch)\(separator)\(repositoryUrl)"

        let mockFileHandler = MockFileHandler(handleFileExists: {
            #expect($0 == rawProjectSourceValue)
            return false
        })

        let projectSource = try ProjectSource.from(
            "\(branch)\(separator)\(repositoryUrl)",
            fileHandler: mockFileHandler
        )

        #expect(
            projectSource ==
            .git(branch: branch, repository: repositoryUrl)
        )
    }

    @Test func remoteInvalidRepoUrl() throws {
        let repositoryUrl = ""
        let separator = ProjectSource.gitSourceSeparator
        let branch = "develop"
        let rawProjectSourceValue = "\(branch)\(separator)\(repositoryUrl)"

        let mockFileHandler = MockFileHandler(handleFileExists: {
            #expect($0 == rawProjectSourceValue)
            return false
        })

        #expect(throws: ProjectSource.Error.invalidSourceValue(value: rawProjectSourceValue)) {
            try ProjectSource.from(
                rawProjectSourceValue,
                fileHandler: mockFileHandler
            )
        }
    }

    @Test func remoteInvalidSeparator() throws {
        let repositoryUrl = "https://github.com/Adyen/adyen-ios.git"
        let separator = "_"
        let branch = "develop"
        let rawProjectSourceValue = "\(branch)\(separator)\(repositoryUrl)"

        let mockFileHandler = MockFileHandler(handleFileExists: {
            #expect($0 == rawProjectSourceValue)
            return false
        })

        #expect(throws: ProjectSource.Error.invalidSourceValue(value: rawProjectSourceValue)) {
            try ProjectSource.from(
                rawProjectSourceValue,
                fileHandler: mockFileHandler
            )
        }
    }

    // MARK: - Local

    @Test func localValidSource() throws {
        let repositoryDirectoryPath = "/Some/Repository/Directory"
        let mockFileHandler = MockFileHandler(handleFileExists: {
            #expect($0 == repositoryDirectoryPath)
            return true
        })

        let projectSource = try ProjectSource.from(
            repositoryDirectoryPath,
            fileHandler: mockFileHandler
        )

        #expect(
            projectSource ==
            .local(path: repositoryDirectoryPath)
        )
    }

    @Test func localNonExistentDirectory() throws {
        let repositoryDirectoryPath = "/Some/Repository/Directory"
        let mockFileHandler = MockFileHandler(handleFileExists: {
            #expect($0 == repositoryDirectoryPath)
            return false
        })

        let projectSource = try? ProjectSource.from(
            repositoryDirectoryPath,
            fileHandler: mockFileHandler
        )

        #expect(projectSource == nil)
    }
}
