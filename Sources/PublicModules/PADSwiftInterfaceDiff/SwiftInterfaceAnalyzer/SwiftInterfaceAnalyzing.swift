//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

public struct SwiftInterfaceAnalysis {
    public let changes: [Change]
    public let metrics: SwiftInterfaceMetricsDiff
}

protocol SwiftInterfaceAnalyzing {
    func analyze(old: some SwiftInterfaceElement, new: some SwiftInterfaceElement) throws -> SwiftInterfaceAnalysis
}
