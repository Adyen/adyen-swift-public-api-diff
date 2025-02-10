//
//  SwiftPackageFileAnalyzer+Targets.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 10/02/2025.
//

import Foundation

import PADCore
import PADLogging

import FileHandlingModule
import ShellModule
import SwiftPackageFileHelperModule

extension SwiftPackageFileAnalyzer {
    
    internal func analyzeTargets(
        old: [SwiftPackageDescription.Target],
        new: [SwiftPackageDescription.Target],
        oldProjectBasePath: String,
        newProjectBasePath: String
    ) throws -> [Change] {
        guard old != new else { return [] }
        
        let oldTargetNames = Set(old.map(\.name))
        let newTargetNames = Set(new.map(\.name))
        
        let added = newTargetNames.subtracting(oldTargetNames)
        let removed = oldTargetNames.subtracting(newTargetNames)
        let consistent = Set(oldTargetNames).intersection(Set(newTargetNames))
        
        var changes = [Change]()
        
        changes += added.compactMap { addition in
            guard let addedTarget = new.first(where: { $0.name == addition }) else { return nil }
            return .init(
                changeType: .addition(description: addedTarget.description),
                parentPath: Constants.packageFileName(child: "targets")
            )
        }
        
        try consistent.forEach { productName in
            guard
                let oldTarget = old.first(where: { $0.name == productName }),
                let newTarget = new.first(where: { $0.name == productName })
            else { return }
            
            changes += try analyzeTarget(
                oldTarget: oldTarget,
                newTarget: newTarget,
                oldProjectBasePath: oldProjectBasePath,
                newProjectBasePath: newProjectBasePath
            )
        }
        
        changes += removed.compactMap { removal in
            guard let removedTarget = old.first(where: { $0.name == removal }) else { return nil }
            return .init(
                changeType: .removal(description: removedTarget.description),
                parentPath: Constants.packageFileName(child: "targets")
            )
        }
        
        return changes
    }
    
    private func analyzeTarget(
        oldTarget: SwiftPackageDescription.Target,
        newTarget: SwiftPackageDescription.Target,
        oldProjectBasePath: String,
        newProjectBasePath: String
    ) throws -> [Change] {
        guard oldTarget != newTarget else { return [] }
        
        var listOfChanges = analyzeDependencies(
            oldTarget: oldTarget,
            newTarget: newTarget
        )
        
        listOfChanges += try analyzeTargetResources(
            oldResources: oldTarget.resources ?? [],
            newResources: newTarget.resources ?? [],
            oldProjectBasePath: oldProjectBasePath,
            newProjectBasePath: newProjectBasePath
        )
        
        if oldTarget.path != newTarget.path {
            listOfChanges += ["Changed path from \"\(oldTarget.path)\" to \"\(newTarget.path)\""]
        }
        
        if oldTarget.type != newTarget.type {
            listOfChanges += ["Changed type from `.\(oldTarget.type.description)` to `.\(newTarget.type.description)`"]
        }
        
        guard oldTarget.description != newTarget.description || !listOfChanges.isEmpty else { return [] }
        
        return [.init(
            changeType: .modification(
                oldDescription: oldTarget.description,
                newDescription: newTarget.description
            ),
            parentPath: Constants.packageFileName(child: "targets"),
            listOfChanges: listOfChanges
        )]
        
    }
}

// MARK: - SwiftPackageDescription.Target.Resource

private extension SwiftPackageFileAnalyzer {
    
    func analyzeDependencies(
        oldTarget: SwiftPackageDescription.Target,
        newTarget: SwiftPackageDescription.Target
    ) -> [String] {
        
        let oldTargetDependencies = Set(oldTarget.targetDependencies ?? [])
        let newTargetDependencies = Set(newTarget.targetDependencies ?? [])
        
        let addedTargetDependencies = newTargetDependencies.subtracting(oldTargetDependencies)
        let removedTargetDependencies = oldTargetDependencies.subtracting(newTargetDependencies)
        
        let oldProductDependencies = Set(oldTarget.productDependencies ?? [])
        let newProductDependencies = Set(newTarget.productDependencies ?? [])
        
        let addedProductDependencies = newProductDependencies.subtracting(oldProductDependencies)
        let removedProductDependencies = oldProductDependencies.subtracting(newProductDependencies)
        
        var listOfChanges = [String]()
        listOfChanges += addedTargetDependencies.map { "Added dependency .target(name: \"\($0)\")" }
        listOfChanges += addedProductDependencies.map { "Added dependency .product(name: \"\($0)\", ...)" }
        listOfChanges += removedTargetDependencies.map { "Removed dependency .target(name: \"\($0)\")" }
        listOfChanges += removedProductDependencies.map { "Removed dependency .product(name: \"\($0)\", ...)" }
        return listOfChanges
    }
    
    func analyzeTargetResources(
        oldResources: [SwiftPackageDescription.Target.Resource],
        newResources: [SwiftPackageDescription.Target.Resource],
        oldProjectBasePath: String,
        newProjectBasePath: String
    ) throws -> [String] {
        
        let oldResourcePaths = Set(oldResources.map(\.path).map { $0.trimmingPrefix(oldProjectBasePath) })
        let newResourcePaths = Set(newResources.map(\.path).map { $0.trimmingPrefix(newProjectBasePath) })
        
        let addedResourcePaths = newResourcePaths.subtracting(oldResourcePaths)
        let consistentResourcePaths = oldResourcePaths.intersection(newResourcePaths)
        let removedResourcePaths = oldResourcePaths.subtracting(newResourcePaths)
        
        var listOfChanges = [String]()
        
        listOfChanges += addedResourcePaths.compactMap { path in
            guard let resource = newResources.first(where: { $0.path.trimmingPrefix(newProjectBasePath) == path }) else { return nil }
            return "Added resource \(resource.description)"
        }
        
        listOfChanges += consistentResourcePaths.compactMap { path in
            guard
                let newResource = newResources.first(where: { $0.path.trimmingPrefix(newProjectBasePath) == path }),
                let oldResource = oldResources.first(where: { $0.path.trimmingPrefix(oldProjectBasePath) == path }),
                newResource.description != oldResource.description
            else { return nil }
            
            return "Changed resource from `\(oldResource.description)` to `\(newResource.description)`"
        }
        
        listOfChanges += removedResourcePaths.compactMap { path in
            guard let resource = oldResources.first(where: { $0.path.trimmingPrefix(oldProjectBasePath) == path }) else { return nil }
            return "Removed resource \(resource.description)"
        }
        
        // TODO: Remove this again!
        listOfChanges += ["[DEBUG] Old project base path \(oldProjectBasePath)"]
        listOfChanges += ["[DEBUG] New project base path \(newProjectBasePath)"]
        
        return listOfChanges
    }
}

// MARK: - Convenience Extension

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        var trimmed = self
        trimmed.trimPrefix(prefix)
        return trimmed
    }
}
