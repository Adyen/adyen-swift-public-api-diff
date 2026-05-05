//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import FileHandlingModule
import Testing

@Suite
struct FileHandlingTests {

    @Test func write() throws {

        let output = "output"
        let filePath = "output/file/path.txt"

        var fileHandler = MockFileHandler()
        fileHandler.handleRemoveItem = { path in
            #expect(path == filePath)
        }

        // Success scenario

        fileHandler.handleCreateFile = { path, data in
            #expect(path == filePath)
            #expect(String(data: data, encoding: .utf8) == output)
            return true
        }

        try fileHandler.write(output, to: filePath)

        // Fail scenario

        fileHandler.handleCreateFile = { _, _ in
            false
        }

        #expect(throws: FileHandlerError.couldNotCreateFile(outputFilePath: filePath)) {
            try fileHandler.write(output, to: filePath)
        }
    }

    @Test func createCleanRepositorySuccess() throws {

        let filePath = "directory/path"

        var fileHandler = MockFileHandler()
        fileHandler.handleRemoveItem = { path in
            #expect(path == filePath)
            throw FileHandlerError.pathDoesNotExist(path: path) // This error should not cause an exception and "fail" gracefully
        }
        fileHandler.handleCreateDirectory = { path in
            #expect(path == filePath)
        }

        try fileHandler.createCleanDirectory(atPath: filePath)
    }

    @Test func createCleanRepositoryFailure() throws {

        let filePath = "directory/path"

        var fileHandler = MockFileHandler()
        fileHandler.handleRemoveItem = { path in
            #expect(path == filePath)
            throw FileHandlerError.pathDoesNotExist(path: path) // This error should not cause an exception and "fail" gracefully
        }
        fileHandler.handleCreateDirectory = { path in
            #expect(path == filePath)
            throw FileHandlerError.couldNotCreateFile(outputFilePath: path)
        }

        #expect(throws: FileHandlerError.couldNotCreateFile(outputFilePath: filePath)) {
            try fileHandler.createCleanDirectory(atPath: filePath)
        }
    }

    @Test func load() throws {

        let filePath = "input/file/path.txt"
        let expectedContent = "content"

        var fileHandler = MockFileHandler()

        // Success scenario

        fileHandler.handleLoadData = { path in
            #expect(path == filePath)
            return try #require(expectedContent.data(using: .utf8))
        }

        let content = try fileHandler.loadString(from: filePath)
        #expect(expectedContent == content)

        // Fail scenario

        fileHandler.handleLoadData = { path in
            throw FileHandlerError.couldNotLoadFile(filePath: path)
        }

        #expect(throws: FileHandlerError.couldNotLoadFile(filePath: filePath)) {
            _ = try fileHandler.loadString(from: filePath)
        }
    }
}
