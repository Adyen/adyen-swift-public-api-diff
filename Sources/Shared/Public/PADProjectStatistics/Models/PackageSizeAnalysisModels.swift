//
//  PackageSizeAnalysis.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 24/10/2024.
//


public struct PackageSizeAnalysis {
    public internal(set) var productSizes: [ProductSizeAnalysis] = []
}

public struct ProductSizeAnalysis {
    public var totalSize: SizeInBytes {
        let totalSize = targetSizes.values.reduce(0, { $0 + $1 })
        return dependencySizes.values.reduce(totalSize, { $0 + $1 })
    }
    
    public let productName: String
    public internal(set)var targetSizes: [String: SizeInBytes] = [:]
    public internal(set)var dependencySizes: [String: SizeInBytes] = [:]
}
