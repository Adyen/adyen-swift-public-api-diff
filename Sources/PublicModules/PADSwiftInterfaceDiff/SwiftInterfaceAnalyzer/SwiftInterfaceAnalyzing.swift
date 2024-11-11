import Foundation
import PADCore

public struct SwiftInterfaceAnalysis {
    public let changes: [Change]
    public let metrics: SwiftInterfaceMetricsDiff
}

protocol SwiftInterfaceAnalyzing {
    func analyze(old: some SwiftInterfaceElement, new: some SwiftInterfaceElement) throws -> SwiftInterfaceAnalysis
}
