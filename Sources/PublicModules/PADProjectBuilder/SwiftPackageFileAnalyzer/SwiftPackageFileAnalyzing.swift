import Foundation
import PADCore

struct SwiftPackageFileAnalyzingResult {
    let changes: [PADChange]
    let warnings: [String]
}

protocol SwiftPackageFileAnalyzing {
    /// Analyzes whether or not the available libraries changed between the old and new version
    func analyze(
        oldProjectUrl: URL,
        newProjectUrl: URL
    ) throws -> SwiftPackageFileAnalyzingResult
}