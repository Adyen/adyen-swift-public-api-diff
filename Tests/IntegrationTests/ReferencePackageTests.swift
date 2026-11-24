//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADCore
@testable import PADOutputGenerator
@testable import PADProjectBuilder
@testable import PADSwiftInterfaceDiff
@testable import PADLogging
import ShellModule
import Testing
import Foundation

@Suite(.serialized)
struct ReferencePackageTests {

    func setUp() async throws {

        let referencePackagesRoot = try Self.referencePackagesPath()
        let oldReferencePackageDirectory = referencePackagesRoot.appending(path: "ReferencePackage")
        let newReferencePackageDirectory = referencePackagesRoot.appending(path: "UpdatedPackage")

        if
            FileManager.default.fileExists(atPath: oldReferencePackageDirectory.appending(path: XcodeTools.Constants.buildDirPath).path()),
            FileManager.default.fileExists(atPath: newReferencePackageDirectory.appending(path: XcodeTools.Constants.buildDirPath).path()) {
            return // Nothing to build
        }

        let xcodeTools = XcodeTools(
            shell: Shell(logger: nil),
            logger: nil
        )

        _ = try await xcodeTools.archive(
            projectDirectoryPath: oldReferencePackageDirectory.path(),
            scheme: "ReferencePackage",
            projectType: .swiftPackage,
            platform: .macOS
        )
        _ = try await xcodeTools.archive(
            projectDirectoryPath: newReferencePackageDirectory.path(),
            scheme: "ReferencePackage",
            projectType: .swiftPackage,
            platform: .macOS
        )
    }

    func tearDown() {

        guard let referencePackagesRoot = try? Self.referencePackagesPath() else { return }
        let oldReferencePackageDirectory = referencePackagesRoot.appending(path: "ReferencePackage").appending(path: XcodeTools.Constants.derivedDataPath)
        let newReferencePackageDirectory = referencePackagesRoot.appending(path: "UpdatedPackage").appending(path: XcodeTools.Constants.derivedDataPath)

        try? FileManager.default.removeItem(at: oldReferencePackageDirectory)
        try? FileManager.default.removeItem(at: newReferencePackageDirectory)
    }

    @Test func swiftInterfacePublic() async throws {
        try await setUp()
        defer { tearDown() }
        try await verifyMarkdown(for: .public, oldVersionName: "old_public", newVersionName: "new_public")
    }

    @Test func swiftInterfacePrivate() async throws {
        try await setUp()
        defer { tearDown() }
        try await verifyMarkdown(for: .private, oldVersionName: "old_private", newVersionName: "new_private")
    }
    @Test func swiftInterfacePublicJSON() async throws {
        try await setUp()
        defer { tearDown() }
        try await verifyJSON(for: .public, oldVersionName: "old_public", newVersionName: "new_public")
    }

    @Test func swiftInterfacePrivateJSON() async throws {
        try await setUp()
        defer { tearDown() }
        try await verifyJSON(for: .private, oldVersionName: "old_private", newVersionName: "new_private")
    }
}

private extension ReferencePackageTests {

    /// Whether to (re-)record the reference files instead of comparing with them
    ///
    /// To (re-)record the reference files run the tests with the environment variable `RECORD_REFERENCES=1`
    var isRecording: Bool {
        ProcessInfo.processInfo.environment["RECORD_REFERENCES"] == "1"
    }

    func record(_ output: String, for interfaceType: InterfaceType, fileExtension: String) throws {
        let resourcesDirectory = try Self.referencePackagesPath()
            .deletingLastPathComponent()
            .appending(path: "Tests/IntegrationTests/Resources")
        let file = resourcesDirectory.appending(path: "\(interfaceType.expectedOutputFileName).\(fileExtension)")
        try output.write(to: file, atomically: true, encoding: .utf8)
    }

    /// Compares the Markdown output line by line with the reference file (ignoring the line with local paths)
    func verifyMarkdown(for interfaceType: InterfaceType, oldVersionName: String, newVersionName: String) async throws {
        let pipelineOutput = try await runPipeline(for: interfaceType)

        let markdownOutput = MarkdownOutputGenerator().generate(
            from: pipelineOutput,
            allTargets: ["ReferencePackage"],
            oldVersionName: oldVersionName,
            newVersionName: newVersionName,
            platform: nil,
            warnings: []
        )

        if isRecording {
            try record(markdownOutput + "\n", for: interfaceType, fileExtension: "md")
            return
        }

        let expectedLines = sanitizeOutput(try expectedOutput(for: interfaceType)).components(separatedBy: "\n")
        let markdownOutputLines = sanitizeOutput(markdownOutput).components(separatedBy: "\n")

        for (index, (expectedLine, outputLine)) in zip(expectedLines, markdownOutputLines).enumerated() where expectedLine != outputLine {
            #expect(expectedLine == outputLine, "Issue in line \(index)")
            return
        }
        #expect(expectedLines.count == markdownOutputLines.count, "Unexpected number of lines")
    }

    /// Compares the JSON output byte for byte with the reference file.
    func verifyJSON(for interfaceType: InterfaceType, oldVersionName: String, newVersionName: String) async throws {
        let pipelineOutput = try await runPipeline(for: interfaceType)

        let jsonOutput = try JSONOutputGenerator(toolVersion: nil).generate(
            from: pipelineOutput,
            allTargets: ["ReferencePackage"],
            oldVersionName: oldVersionName,
            newVersionName: newVersionName,
            platform: nil,
            warnings: []
        )

        if isRecording {
            try record(jsonOutput, for: interfaceType, fileExtension: "json")
            return
        }

        let path = try #require(Bundle.module.path(forResource: interfaceType.expectedOutputFileName, ofType: "json"))
        let expected = try String(contentsOfFile: path, encoding: .utf8)

        #expect(jsonOutput == expected)
    }
    static func referencePackagesPath() throws -> URL {
        // Unfortunately we can't use packages as Test Resources, so we put it in a `ReferencePackages` directory on root
        guard let projectRoot = #file.replacingOccurrences(of: "relatve/path/to/file", with: "").split(separator: "/Tests/").first else {
            struct CannotFindRootDirectoryError: Error {}
            throw CannotFindRootDirectoryError()
        }

        return URL(filePath: String(projectRoot)).appending(path: "ReferencePackages")
    }

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
                "\(XcodeTools.Constants.derivedDataPath)/Build/Products/Debug/ReferencePackage.swiftmodule/arm64-apple-macos.swiftinterface"
            case .private:
                "\(XcodeTools.Constants.derivedDataPath)/Build/Products/Debug/ReferencePackage.swiftmodule/arm64-apple-macos.private.swiftinterface"
            }
        }
    }

    func expectedOutput(for source: InterfaceType) throws -> String {
        let expectedOutputFilePath = try #require(Bundle.module.path(forResource: source.expectedOutputFileName, ofType: "md"))
        let expectedOutputData = try #require(FileManager.default.contents(atPath: expectedOutputFilePath))
        return try #require(String(data: expectedOutputData, encoding: .utf8))
    }

    func swiftInterfaceFilePath(for referencePackagesRoot: URL, packageName: String, interfaceType: InterfaceType) throws -> String {
        let oldReferencePackageDirectory = referencePackagesRoot.appending(path: packageName)
        let interfaceFilePath = oldReferencePackageDirectory.appending(path: interfaceType.interfaceFilePath)
        return interfaceFilePath.path()
    }

    func runPipeline(for interfaceType: InterfaceType) async throws -> [String: [Change]] {

        let referencePackagesRoot = try Self.referencePackagesPath()

        let oldPrivateSwiftInterfaceFilePath = try swiftInterfaceFilePath(
            for: referencePackagesRoot,
            packageName: "ReferencePackage",
            interfaceType: interfaceType
        )

        let newPrivateSwiftInterfaceFilePath = try swiftInterfaceFilePath(
            for: referencePackagesRoot,
            packageName: "UpdatedPackage",
            interfaceType: interfaceType
        )

        let interfaceFiles = [
            SwiftInterfaceFile(
                name: "ReferencePackage",
                oldFilePath: oldPrivateSwiftInterfaceFilePath,
                newFilePath: newPrivateSwiftInterfaceFilePath
            )
        ]

        return try await SwiftInterfaceDiff(
            fileHandler: FileManager.default,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
            logger: nil
        ).run(with: interfaceFiles)
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
