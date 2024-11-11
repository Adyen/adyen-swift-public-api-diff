//
//  SwiftInterfaceMetrics.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 11/11/2024.
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
