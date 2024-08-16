//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
import XCTest

class ReferencePackageTests: XCTestCase {
    
    func test_defaultPipeline() async throws {
        
        // Unfortunately we can't use packages as Test Resources, so we put it in a `ReferencePackages` directory on root
        guard let projectRoot = #file.replacingOccurrences(of: "relatve/path/to/file", with: "").split(separator: "/Tests/").first else {
            XCTFail("Cannot find root directory")
            return
        }
        
        let referencePackagesRoot = URL(filePath: String(projectRoot)).appending(path: "ReferencePackages")
        
        let oldReferencePackageDirectory = referencePackagesRoot.appending(path: "ReferencePackage")
        let newReferencePackageDirectory = referencePackagesRoot.appending(path: "UpdatedPackage")
        
        let expectedOutput: String = try {
            let expectedOutputFilePath = try XCTUnwrap(Bundle.module.path(forResource: "expected-reference-changes", ofType: "md"))
            let expectedOutputData = try XCTUnwrap(FileManager.default.contents(atPath: expectedOutputFilePath))
            return try XCTUnwrap(String(data: expectedOutputData, encoding: .utf8))
        }()
        
        let fileHandler: FileHandling = FileManager.default
        let logger: any Logging = PipelineLogger(logLevel: .debug)
        
        let currentDirectory = fileHandler.currentDirectoryPath
        let workingDirectoryPath = currentDirectory.appending("/tmp-public-api-diff")
        
        let pipelineOutput = try await Pipeline.run(
            newSource: .local(path: newReferencePackageDirectory.path()),
            oldSource: .local(path: oldReferencePackageDirectory.path()),
            scheme: nil,
            workingDirectoryPath: workingDirectoryPath,
            fileHandler: fileHandler,
            logger: logger
        )
        
        print("Expected Output")
        print(sanitizeOutput(expectedOutput))
        print("----------------------------------------------------")
        
        print("Pipeline Output")
        print(sanitizeOutput(pipelineOutput))
        print("----------------------------------------------------")
        
        let expectedLines = sanitizeOutput(expectedOutput).components(separatedBy: "\n")
        let pipelineOutputLines = sanitizeOutput(pipelineOutput).components(separatedBy: "\n")
        
        for i in 0..<expectedLines.count  {
            XCTAssertEqual(expectedLines[i], pipelineOutputLines[i])
        }
    }
}

private extension ReferencePackageTests {
    
    /// Removes the 2nd line that contains local file paths + empty newline at the end of the content if it exists
    func sanitizeOutput(_ output: String) -> String {
        var lines = output.components(separatedBy: "\n")
        lines.remove(at: 1) // 2nd line contains context specific paths
        if lines.last?.isEmpty == true {
            lines.removeLast() // Last line is empty because of empty newline
        }
        return lines.joined(separator: "\n")
    }
}
