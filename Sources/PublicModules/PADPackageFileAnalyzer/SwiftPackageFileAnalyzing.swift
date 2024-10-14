import Foundation
import PADCore

public struct SwiftPackageFileAnalyzingResult {
    /// The changes between 2 `Package.swift` files
    public let changes: [Change]
    /// Any warnings that occured while inspecting the `Package.swift` file
    public let warnings: [String]
}

protocol SwiftPackageFileAnalyzing {
    /// Analyzes 2 versions of a `Package.swift` and returns a `SwiftPackageFileAnalyzingResult` containing the findings
    /// - Parameters:
    ///   - oldProjectUrl: The directory url to the reference project
    ///   - newProjectUrl: The directory url to the updated project
    /// - Returns: A `SwiftPackageFileAnalyzingResult` containing the findings
    func analyze(
        oldProjectUrl: URL,
        newProjectUrl: URL
    ) throws -> SwiftPackageFileAnalyzingResult
}
