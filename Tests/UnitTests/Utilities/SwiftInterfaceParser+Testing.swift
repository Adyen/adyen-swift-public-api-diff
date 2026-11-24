//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADSwiftInterfaceDiff
import Testing

extension SwiftInterfaceParser {

    /// Parses a test source that is expected to be valid Swift, recording an issue if it contains syntax errors
    func parseValid(
        source: String,
        moduleName: String,
        apiScope: APIScope = .all,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> any SwiftInterfaceElement {
        do {
            return try parse(source: source, moduleName: moduleName, apiScope: apiScope)
        } catch {
            Issue.record(error, sourceLocation: sourceLocation)
            return Root(moduleName: moduleName, elements: [])
        }
    }
}
