//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
import XCTest

class ReferencePackageTests: XCTestCase {
     
    func test_swiftInterface() throws {

        // TODO: Build + use the pipeline
        
        // Public interface
        
        try test(swiftInterface: .public)
        
        // @_spi interface
        
        try test(swiftInterface: .private)
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
    
    func swiftInterfaceContent(referencePackagesRoot: URL, packageName: String, interfaceType: InterfaceType) throws-> String {
        let oldReferencePackageDirectory = referencePackagesRoot.appending(path: packageName)
        let interfaceFilePath = try XCTUnwrap(oldReferencePackageDirectory.appending(path: interfaceType.interfaceFilePath))
        let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: interfaceFilePath.path()))
        return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
    }
    
    func content(atPath path: String) throws -> String {
        let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: path))
        return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
    }
    
    func test(swiftInterface interface: InterfaceType) throws {
        // Unfortunately we can't use packages as Test Resources, so we put it in a `ReferencePackages` directory on root
        guard let projectRoot = #file.replacingOccurrences(of: "relatve/path/to/file", with: "").split(separator: "/Tests/").first else {
            XCTFail("Cannot find root directory")
            return
        }
        
        let referencePackagesRoot = URL(filePath: String(projectRoot)).appending(path: "ReferencePackages")
        
        let expectedOutput = try expectedOutput(for: interface)
        
        let oldSourceContent = try swiftInterfaceContent(
            referencePackagesRoot: referencePackagesRoot,
            packageName: "ReferencePackage",
            interfaceType: interface
        )
        
        let newSourceContent = try swiftInterfaceContent(
            referencePackagesRoot: referencePackagesRoot,
            packageName: "UpdatedPackage",
            interfaceType: interface
        )
        
        /*
        let oldSourceContent = try content(atPath: "/Users/alexandergu/Downloads/AdyenPOS.xcframework/ios-arm64_x86_64-simulator/AdyenPOS.framework/Modules/AdyenPOS.swiftmodule/arm64-apple-ios-simulator.swiftinterface")
        let newSourceContent = try content(atPath: "/Users/alexandergu/Downloads/AdyenPOS/AdyenPOS_3.2.0.xcframework/ios-arm64_x86_64-simulator/AdyenPOS.framework/Modules/AdyenPOS.swiftmodule/arm64-apple-ios-simulator.swiftinterface")
         */
        
        let oldInterface = SwiftInterfaceParser.parse(source: oldSourceContent, moduleName: "ReferencePackage")
        let newInterface = SwiftInterfaceParser.parse(source: newSourceContent, moduleName: "ReferencePackage")
        
        let analyzer = SwiftInterfaceAnalyzer()
        
        let changes = analyzer.analyze(old: oldInterface, new: newInterface)
     
        let markdownOutput = MarkdownOutputGenerator().generate(
            from: ["ReferencePackage": changes],
            allTargets: ["ReferencePackage"],
            oldSource: .local(path: "AdyenPOS 2.2.2"),
            newSource: .local(path: "AdyenPOS 3.2.0"),
            warnings: []
        )
        
        print(markdownOutput)
        
        let expectedLines = sanitizeOutput(expectedOutput).components(separatedBy: "\n")
        let markdownOutputLines = sanitizeOutput(markdownOutput).components(separatedBy: "\n")
        
        for i in 0..<expectedLines.count  {
            if expectedLines[i] != markdownOutputLines[i] {
                XCTAssertEqual(expectedLines[i], markdownOutputLines[i])
                return
            }
        }
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
