//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

/// The version of the command line tool
///
/// Updated by the `Prepare Release` workflow (`.github/workflows/create-release.yml`) so a tagged commit always contains its own version.
/// Builds from other commits report the version of the last release.
///
/// Used for `--version` and for `tool.version` in the JSON output.
/// Note: Consumers of the JSON output should rely on `formatVersion`, not on this value.
enum ToolVersion {
    static let current = "0.13.0"
}
