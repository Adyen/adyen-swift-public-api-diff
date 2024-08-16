//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
import XCTest

class ReferencePackageTests: XCTestCase {
    
    func test_basicPipeline() async throws {
        
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
            var expectedOutput = try XCTUnwrap(String(data: expectedOutputData, encoding: .utf8))
            if expectedOutput.hasSuffix("\n") {
                expectedOutput.removeLast(1) // \n only counts as one character
            }
            return expectedOutput
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
        
        XCTAssertEqual(expectedOutput, pipelineOutput)
    }
}
