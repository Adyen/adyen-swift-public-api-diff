//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

public struct SwiftInterfaceMetricsDiff {
    public let old: SwiftInterfaceMetrics
    public let new: SwiftInterfaceMetrics
    
    package init(old: SwiftInterfaceMetrics, new: SwiftInterfaceMetrics) {
        self.old = old
        self.new = new
    }
}

public struct SwiftInterfaceMetrics {
    
    public package(set) var occurencesOfType = [SwiftInterfaceElementDeclType: Int]()
    
    package init(occurencesOfType: [SwiftInterfaceElementDeclType: Int] = [SwiftInterfaceElementDeclType: Int]()) {
        self.occurencesOfType = occurencesOfType
    }
    
    package mutating func increment(_ type: SwiftInterfaceElementDeclType) {
        occurencesOfType[type] = (occurencesOfType[type] ?? 0) + 1
    }
    
    package mutating func add(count: Int, of type: SwiftInterfaceElementDeclType) {
        occurencesOfType[type] = (occurencesOfType[type] ?? 0) + count
    }
    
    package mutating func adding(_ metrics: SwiftInterfaceMetrics) {
        SwiftInterfaceElementDeclType.allCases.forEach { type in
            add(count: metrics.occurencesOfType[type] ?? 0, of: type)
        }
    }
}
