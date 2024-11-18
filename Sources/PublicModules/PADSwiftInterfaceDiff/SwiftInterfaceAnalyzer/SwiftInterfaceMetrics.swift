//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import PADCore

extension SwiftInterfaceElement {
    
    func metrics() -> SwiftInterfaceMetrics {
        var metrics = SwiftInterfaceMetrics()
        metrics.increment(Self.declType)
        children.forEach { metrics.adding($0.metrics()) }
        return metrics
    }
}
