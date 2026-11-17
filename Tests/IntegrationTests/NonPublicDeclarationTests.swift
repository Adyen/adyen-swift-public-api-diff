//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADCore
@testable import PADSwiftInterfaceDiff
import Foundation
import Testing

/// Interfaces generated without library evolution contain `private`, `fileprivate` and `internal` declarations.
/// Comparing them must produce the same result as comparing interfaces that only contain the public API.
@Suite
struct NonPublicDeclarationTests {

    @Test func nonPublicDeclarationsDoNotAffectTheReport() async throws {
        let withNonPublic = try await runPipeline(old: "old-with-non-public", new: "new-with-non-public")
        let publicOnly = try await runPipeline(old: "old-public-only", new: "new-public-only")

        #expect(!publicOnly["Example", default: []].isEmpty)
        #expect(withNonPublic == publicOnly)
    }

    private func runPipeline(old: String, new: String) async throws -> [String: [Change]] {
        try await SwiftInterfaceDiff(
            fileHandler: FileManager.default,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
            logger: nil
        ).run(with: [
            SwiftInterfaceFile(
                name: "Example",
                oldFilePath: try fixturePath(old),
                newFilePath: try fixturePath(new)
            )
        ])
    }

    private func fixturePath(_ name: String) throws -> String {
        try #require(Bundle.module.path(forResource: name, ofType: "swiftinterface", inDirectory: "NonPublicDeclarations"))
    }
}
