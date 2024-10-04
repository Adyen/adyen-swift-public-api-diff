//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
import XCTest

class ReferencePackageTests: XCTestCase {
     
    func test_swiftInterface() async throws {

        // Unfortunately we can't use packages as Test Resources, so we put it in a `ReferencePackages` directory on root
        guard let projectRoot = #file.replacingOccurrences(of: "relatve/path/to/file", with: "").split(separator: "/Tests/").first else {
            XCTFail("Cannot find root directory")
            return
        }
        
        let referencePackagesRoot = URL(filePath: String(projectRoot)).appending(path: "ReferencePackages")
        
        /*
        let oldSourceContent = try content(atPath: "/Users/alexandergu/Downloads/AdyenPOS.xcframework/ios-arm64_x86_64-simulator/AdyenPOS.framework/Modules/AdyenPOS.swiftmodule/arm64-apple-ios-simulator.swiftinterface")
        let newSourceContent = try content(atPath: "/Users/alexandergu/Downloads/AdyenPOS/AdyenPOS_3.2.0.xcframework/ios-arm64_x86_64-simulator/AdyenPOS.framework/Modules/AdyenPOS.swiftmodule/arm64-apple-ios-simulator.swiftinterface")
         */
        
        let oldPrivateSwiftInterfaceFilePath = try swiftInterfaceFilePath(
            for: referencePackagesRoot,
            packageName: "ReferencePackage",
            interfaceType: .private
        )
        
        let newPrivateSwiftInterfaceFilePath = try swiftInterfaceFilePath(
            for: referencePackagesRoot,
            packageName: "UpdatedPackage",
            interfaceType: .private
        )
        
        let oldPublicSwiftInterfaceFilePath = try swiftInterfaceFilePath(
            for: referencePackagesRoot,
            packageName: "ReferencePackage",
            interfaceType: .public
        )
        
        let newPublicSwiftInterfaceFilePath = try swiftInterfaceFilePath(
            for: referencePackagesRoot,
            packageName: "UpdatedPackage",
            interfaceType: .public
        )
        
        let pipelineOutput = try await SwiftInterfacePipeline(
            swiftInterfaceFiles: [
                .newAndOld(
                    name: "ReferencePackage",
                    oldFilePath: oldPrivateSwiftInterfaceFilePath,
                    newFilePath: newPrivateSwiftInterfaceFilePath
                ),
                .old(
                    name: "ReferencePackage",
                    filePath: oldPublicSwiftInterfaceFilePath
                ),
                .new(
                    name: "ReferencePackage",
                    filePath: newPublicSwiftInterfaceFilePath
                )
            ],
            fileHandler: FileManager.default,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
            outputGenerator: MarkdownOutputGenerator(),
            logger: PipelineLogger(logLevel: .debug)
        ).run()
        
        print(pipelineOutput)
        
        /*
         let expectedLines = sanitizeOutput(expectedOutput).components(separatedBy: "\n")
         let markdownOutputLines = sanitizeOutput(markdownOutput).components(separatedBy: "\n")
         
         for i in 0..<expectedLines.count  {
             if expectedLines[i] != markdownOutputLines[i] {
                 XCTAssertEqual(expectedLines[i], markdownOutputLines[i])
                 return
             }
         }
         */
    }
}

private extension ReferencePackageTests {
    
    enum InterfaceType {
        case `public`
        case `private`
        
        var expectedOutputFileName: String {
            switch self {
            case .public:
                "expected-reference-changes-swift-interface-public"
            case .private:
                "expected-reference-changes-swift-interface-private"
            }
        }
        
        var interfaceFilePath: String {
            switch self {
            case .public:
                "_build/Build/Products/Debug-iphoneos/ReferencePackage.swiftmodule/arm64-apple-ios.swiftinterface"
            case .private:
                "_build/Build/Products/Debug-iphoneos/ReferencePackage.swiftmodule/arm64-apple-ios.private.swiftinterface"
            }
        }
    }
    
    func expectedOutput(for source: InterfaceType) throws -> String {
        let expectedOutputFilePath = try XCTUnwrap(Bundle.module.path(forResource: source.expectedOutputFileName, ofType: "md"))
        let expectedOutputData = try XCTUnwrap(FileManager.default.contents(atPath: expectedOutputFilePath))
        return try XCTUnwrap(String(data: expectedOutputData, encoding: .utf8))
    }
    
    func swiftInterfaceFilePath(for referencePackagesRoot: URL, packageName: String, interfaceType: InterfaceType) throws -> String {
        let oldReferencePackageDirectory = referencePackagesRoot.appending(path: packageName)
        let interfaceFilePath = try XCTUnwrap(oldReferencePackageDirectory.appending(path: interfaceType.interfaceFilePath))
        return interfaceFilePath.path()
    }
    
    func content(atPath path: String) throws -> String {
        let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: path))
        return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
    }
    
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
