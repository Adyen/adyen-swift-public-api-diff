import Foundation

import SwiftPackageFileHelperModule
import PADCore

package struct ProjectStatisticsAnalyzer {
    
    package static func analyzeSizes(projectStatistics: ProjectStatistics, swiftPackageDescription: SwiftPackageDescription) -> PackageSizeAnalysis {
        swiftPackageDescription.products.reduce(into: PackageSizeAnalysis()) {
            $0.productSizes += [analyzeSize(of: $1, in: swiftPackageDescription, projectStatistics: projectStatistics)]
        }
    }
    
    package static func analyze(old oldStatistics: ProjectStatistics, new newStatistics: ProjectStatistics) -> [Change] {
        let oldFileNames = Set(oldStatistics.statistics.map(\.name))
        let newFileNames = Set(newStatistics.statistics.map(\.name))
        
        var changes = [Change]()
        
        oldFileNames.subtracting(newFileNames).sorted().forEach { fileName in
            let oldModuleStats = oldStatistics.statistics(forModule: fileName)
            changes.append(.init(changeType: .removal(description: "Removed \(fileName) [\(oldModuleStats.sizeInBytes.bytesFormattedAsMB)]")))
        }
        
        newFileNames.subtracting(oldFileNames).sorted().forEach { fileName in
            let newModuleStats = newStatistics.statistics(forModule: fileName)
            changes.append(.init(changeType: .addition(description: "Added \(fileName) [\(newModuleStats.sizeInBytes.bytesFormattedAsMB)]")))
        }
        
        oldFileNames.intersection(newFileNames).sorted().forEach { fileName in
            let oldModuleStats = oldStatistics.statistics(forModule: fileName)
            let newModuleStats = newStatistics.statistics(forModule: fileName)
            
            if let change = change(forTarget: fileName, oldValue: oldModuleStats.sizeInBytes, newValue: newModuleStats.sizeInBytes) {
                changes.append(change)
            }
        }
        
        return changes
    }
}

private extension ProjectStatisticsAnalyzer {
    
    static func analyzeSize(
        of product: SwiftPackageDescription.Product,
        in swiftPackageDescription: SwiftPackageDescription,
        projectStatistics: ProjectStatistics
    ) -> ProductSizeAnalysis {
        var productSizeAnalysis = ProductSizeAnalysis(productName: product.name)
        
        product.targets.forEach { targetName in
            guard let target = swiftPackageDescription.targets.first(where: { $0.name == targetName }) else { return }
            
            let targetSize = projectStatistics.statistics(forModule: targetName).sizeInBytes
            productSizeAnalysis.targetSizes[targetName] = targetSize
            
            target.targetDependencies?.forEach { // e.g. a target like AdyenDropIn
                let statistics = projectStatistics.statistics(forModule: $0)
                productSizeAnalysis.dependencySizes[$0] = statistics.sizeInBytes
            }
            
            target.productDependencies?.forEach { // e.g. a framework like PayKit
                let statistics = projectStatistics.statistics(forModule: $0)
                productSizeAnalysis.dependencySizes[$0] = statistics.sizeInBytes
            }
        }
        
        return productSizeAnalysis
    }
    
    static func change(forTarget target: String, oldValue: SizeInBytes, newValue: SizeInBytes) -> Change? {
        
        if oldValue == newValue {
            return nil
        } else {
            let changeInPercentage = ((Double(newValue) - Double(oldValue)) / Double(oldValue)) * 100
            let formattedPercentageChange = String(format: "%.2f", changeInPercentage)

            var formattedOldValue = oldValue.bytesFormattedAsMB
            var formattedNewValue = newValue.bytesFormattedAsMB
            
            // Moving to KB if the MB formatting makes them equal
            if formattedOldValue == formattedNewValue {
                formattedOldValue = oldValue.bytesFormattedAsKB
                formattedNewValue = newValue.bytesFormattedAsKB
            }
            
            return .init(
                changeType: .change(
                    oldDescription: formattedOldValue,
                    newDescription: formattedNewValue
                ),
                parentPath: "\(target)",
                listOfChanges: [
                    "\(changeInPercentage > 0 ? "📈" : "📉") \(changeInPercentage > 0 ? "+" : "")\(formattedPercentageChange) %"
                ]
            )
        }
    }
}
