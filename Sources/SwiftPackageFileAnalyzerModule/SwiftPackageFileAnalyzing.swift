import Foundation
import CoreModule

public struct SwiftPackageFileAnalyzingResult {
    public let changes: [Change]
    public let warnings: [String]
}

public protocol SwiftPackageFileAnalyzing {
    /// Analyzes whether or not the available libraries changed between the old and new version
    func analyze(
        oldProjectUrl: URL,
        newProjectUrl: URL
    ) throws -> SwiftPackageFileAnalyzingResult
}
