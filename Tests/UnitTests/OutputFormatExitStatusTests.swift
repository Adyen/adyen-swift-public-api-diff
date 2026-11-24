//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import ArgumentParser
import Foundation
@testable import public_api_diff
import Testing

/// Guards the exit status behaviour of the command line tool when an error occurs.
///
/// WHY THIS DIFFERS PER FORMAT (please read before changing these tests):
///
/// - `json`: A consumer (script, CI step, other tool) can't tell a failure from "no changes" by looking at stdout,
///   as both result in no usable output. So a failure MUST end in a non-zero exit status.
///
/// - `markdown`: Historically the tool logs the error and still exits with status `0`.
///   The GitHub Action and existing user scripts rely on that, so changing it is a breaking change
///   and a decision of its own - it must not happen as a side effect of the JSON work.
///
/// If you want `markdown` to exit non-zero as well, do that deliberately (changelog / major version),
/// then update this test.
@Suite
struct OutputFormatExitStatusTests {

    private struct SomeError: Error {}

    private func logger(logged: @escaping (String) -> Void = { _ in }) -> MockLogger {
        var logger = MockLogger()
        logger.handleLog = { message, _ in logged(message) }
        return logger
    }

    @Test func jsonFormatThrowsNonZeroExitCodeOnError() throws {
        #expect(throws: ExitCode.failure) {
            try PublicApiDiff.handle(SomeError(), format: .json, logger: logger())
        }
    }

    @Test func markdownFormatKeepsExitingWithZeroOnError() throws {
        // Must NOT throw - see the explanation above
        try PublicApiDiff.handle(SomeError(), format: .markdown, logger: logger())
    }

    @Test(arguments: [OutputFormat.markdown, OutputFormat.json])
    func errorIsLoggedInEveryFormat(format: OutputFormat) {
        var messages = [String]()

        _ = try? PublicApiDiff.handle(SomeError(), format: format, logger: logger { messages.append($0) })

        #expect(messages.count == 1)
        #expect(messages.first?.hasPrefix("💥") == true)
    }
}
