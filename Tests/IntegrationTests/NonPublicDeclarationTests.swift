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
/// Comparing them with an ``APIScope`` must produce the same result as comparing interfaces that only contain the API in scope.
@Suite
struct NonPublicDeclarationTests {

    @Test func publicScopeIgnoresPackageAndNonPublicDeclarations() async throws {
        let withNonPublic = try await runPipeline(old: "old-with-non-public", new: "new-with-non-public", apiScope: .public)
        let publicOnly = try await runPipeline(old: "old-public-only", new: "new-public-only", apiScope: .public)

        #expect(!publicOnly["Example", default: []].isEmpty)
        #expect(withNonPublic == publicOnly)
    }

    @Test func packageScopeReportsPackageButNotNonPublicDeclarations() async throws {
        let withNonPublic = try await runPipeline(old: "old-with-non-public", new: "new-with-non-public", apiScope: .package)
        let publicOnly = try await runPipeline(old: "old-public-only", new: "new-public-only", apiScope: .package)

        let changes = withNonPublic["Example", default: []]
        #expect(changes.count == publicOnly["Example", default: []].count + 1)
        #expect(changes.contains { String(describing: $0).contains("sync") })
        #expect(!changes.contains { String(describing: $0).contains("recalculate") })
    }

    @Test func allScopeReportsNonPublicDeclarations() async throws {
        let withNonPublic = try await runPipeline(old: "old-with-non-public", new: "new-with-non-public", apiScope: .all)
        let publicOnly = try await runPipeline(old: "old-public-only", new: "new-public-only", apiScope: .all)

        #expect(withNonPublic != publicOnly)
    }

    private func runPipeline(old: String, new: String, apiScope: APIScope) async throws -> [String: [Change]] {
        try await SwiftInterfaceDiff(
            fileHandler: FileManager.default,
            swiftInterfaceParser: SwiftInterfaceParser(),
            swiftInterfaceAnalyzer: SwiftInterfaceAnalyzer(),
            apiScope: apiScope,
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
