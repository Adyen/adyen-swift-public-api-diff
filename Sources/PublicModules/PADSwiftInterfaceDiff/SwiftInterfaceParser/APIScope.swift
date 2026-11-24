//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

/// Defines which declarations of a `.swiftinterface` are considered part of the API
///
/// Interfaces generated without library evolution (`BUILD_LIBRARY_FOR_DISTRIBUTION = NO`) contain
/// `private`, `fileprivate` and `internal` declarations that are not part of the API.
public enum APIScope: Sendable {

    /// Only `public` and `open` declarations. Drops `package`, `internal`, `fileprivate` and `private`.
    case `public`

    /// `public`, `open` and `package` declarations. Drops `internal`, `fileprivate` and `private`.
    case package

    /// All declarations (no filtering)
    case all
}
