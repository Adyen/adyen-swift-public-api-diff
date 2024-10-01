//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 16/09/2024.
//

@testable import public_api_diff
import XCTest

class SwiftInterfaceTests: XCTestCase {
    
    func test_swiftinterface() throws {
        
        // Unfortunately we can't use packages as Test Resources, so we put it in a `ReferencePackages` directory on root
        guard let projectRoot = #file.replacingOccurrences(of: "relatve/path/to/file", with: "").split(separator: "/Tests/").first else {
            XCTFail("Cannot find root directory")
            return
        }
        
        let referencePackagesRoot = URL(filePath: String(projectRoot)).appending(path: "ReferencePackages")
        
        let expectedOutput: String = try {
            let expectedOutputFilePath = try XCTUnwrap(Bundle.module.path(forResource: "expected-reference-changes", ofType: "md"))
            let expectedOutputData = try XCTUnwrap(FileManager.default.contents(atPath: expectedOutputFilePath))
            return try XCTUnwrap(String(data: expectedOutputData, encoding: .utf8))
        }()
        
        let oldSource: String = try {
            
            let oldReferencePackageDirectory = referencePackagesRoot.appending(path: "ReferencePackage")
            let interfaceFilePath = try XCTUnwrap(oldReferencePackageDirectory.appending(path: "_build/Build/Products/Debug-iphoneos/ReferencePackage.swiftmodule/arm64-apple-ios.private.swiftinterface"))
            let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: interfaceFilePath.path()))
            return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
        }()
        
        let newSource: String = try {
            let newReferencePackageDirectory = referencePackagesRoot.appending(path: "UpdatedPackage")
            let interfaceFilePath = try XCTUnwrap(newReferencePackageDirectory.appending(path: "_build/Build/Products/Debug-iphoneos/ReferencePackage.swiftmodule/arm64-apple-ios.private.swiftinterface"))
            let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: interfaceFilePath.path()))
            return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
        }()

        let oldInterface = SwiftInterfaceParser.parse(source: oldSource)
        let newInterface = SwiftInterfaceParser.parse(source: newSource)
        
        let analyzer = SwiftInterfaceAnalyzer()
        
        if oldInterface != newInterface {
            let changes = analyzer.analyze(old: oldInterface, new: newInterface)
            let output = MarkdownOutputGenerator().generate(
                from: ["": changes],
                allTargets: ["Target"],
                oldSource: .local(path: "old"),
                newSource: .local(path: "new"),
                warnings: []
            )
            print(output)
        }
        
        /*
        let oldRoot = SDKDump(
            root: .init(
                kind: .root,
                name: "TopLevel",
                printedName: "TopLevel",
                children: SwiftInterfaceVisitor.parse(source: oldSource)
            )
        )
        
        let newRoot = SDKDump(
            root: .init(
                kind: .root,
                name: "TopLevel",
                printedName: "TopLevel",
                children: SwiftInterfaceVisitor.parse(source: newSource)
            )
        )
        
        let changes = SDKDumpAnalyzer().analyze(old: oldRoot, new: newRoot)
         
        let markdownOutput = MarkdownOutputGenerator().generate(
            from: ["ReferencePackage": changes],
            allTargets: ["ReferencePackage"],
            oldSource: .local(path: "/.../.../ReferencePackage"),
            newSource: .local(path: "/.../.../UpdatedPackage"),
            warnings: []
        )
        
        XCTAssertEqual(markdownOutput, expectedOutput)
         */
    }
}
