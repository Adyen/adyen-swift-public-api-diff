//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import PADCore
import PADLogging

import FileHandlingModule
import ShellModule
import SwiftPackageFileHelperModule

/// Analyzes 2 versions of a `Package.swift`
public struct SwiftPackageFileAnalyzer: SwiftPackageFileAnalyzing {

    private let fileHandler: any FileHandling
    private let shell: any ShellHandling
    private let logger: (any Logging)?

    private enum Constants {
        static let packageFileName = "Package.swift"
        static func packageFileName(child: String) -> String {
            ".\(child)"
        }
    }

    public init(logger: (any Logging)? = nil) {
        self.init(
            fileHandler: FileManager.default,
            shell: Shell(),
            logger: logger
        )
    }

    package init(
        fileHandler: FileHandling = FileManager.default,
        shell: ShellHandling = Shell(),
        logger: (any Logging)? = nil
    ) {
        self.fileHandler = fileHandler
        self.logger = logger
        self.shell = shell
    }

    public func analyze(
        oldProjectUrl: URL,
        newProjectUrl: URL
    ) throws -> SwiftPackageFileAnalyzingResult {

        let oldProjectPath = oldProjectUrl.path()
        let newProjectPath = newProjectUrl.path()

        let oldPackagePath = SwiftPackageFileHelper.packagePath(for: oldProjectPath)
        let newPackagePath = SwiftPackageFileHelper.packagePath(for: newProjectPath)

        if fileHandler.fileExists(atPath: oldPackagePath), fileHandler.fileExists(atPath: newPackagePath) {
            let packageHelper = SwiftPackageFileHelper(
                fileHandler: fileHandler,
                shell: shell,
                logger: logger
            )

            return try analyze(
                old: packageHelper.packageDescription(at: oldProjectPath),
                new: packageHelper.packageDescription(at: newProjectPath)
            )
        } else {
            return .init(changes: [], warnings: [])
        }
    }
}

private extension SwiftPackageFileAnalyzer {

    /// Compiles all changes between 2 `SwiftPackageDescription`s
    private func analyze(
        old: SwiftPackageDescription,
        new: SwiftPackageDescription
    ) throws -> SwiftPackageFileAnalyzingResult {

        guard old != new else { return .init(changes: [], warnings: []) }

        var changes = [Change]()
        changes += try analyzeToolsVersion(old: old.toolsVersion, new: new.toolsVersion)

        changes += try analyzeDefaultLocalization(old: old.defaultLocalization, new: new.defaultLocalization)
        changes += try analyzeName(old: old.name, new: new.name)

        changes += try analyzePlatforms(old: old.platforms, new: new.platforms)
        changes += try analyzeProducts(old: old.products, new: new.products)
        changes += try analyzeTargets(
            old: old.targets,
            new: new.targets,
            oldProjectBasePath: old.projectBasePath,
            newProjectBasePath: new.projectBasePath
        )
        changes += try analyzeDependencies(old: old.dependencies, new: new.dependencies)

        return .init(changes: changes, warnings: new.warnings)
    }

    // MARK: - Default Localization

    private func analyzeDefaultLocalization(
        old: String?,
        new: String?
    ) throws -> [Change] {
        guard old != new else { return [] }

        let keyName = "defaultLocalization"

        if let old, new == nil {
            return [.init(
                changeType: .removal(description: "\(keyName): \"\(old)\""),
                parentPath: Constants.packageFileName
            )]
        }

        if let new, old == nil {
            return [.init(
                changeType: .addition(description: "\(keyName): \"\(new)\""),
                parentPath: Constants.packageFileName
            )]
        }

        guard let new, let old else { return [] }

        return [.init(
            changeType: .modification(
                oldDescription: "\(keyName): \"\(old)\"",
                newDescription: "\(keyName): \"\(new)\""
            ),
            parentPath: Constants.packageFileName
        )]
    }

    // MARK: - Name

    private func analyzeName(
        old: String,
        new: String
    ) throws -> [Change] {
        guard old != new else { return [] }

        let keyName = "name"

        return [.init(
            changeType: .modification(
                oldDescription: "\(keyName): \"\(old)\"",
                newDescription: "\(keyName): \"\(new)\""
            ),
            parentPath: Constants.packageFileName
        )]
    }

    // MARK: - Platforms

    private func analyzePlatforms(
        old: [SwiftPackageDescription.Platform],
        new: [SwiftPackageDescription.Platform]
    ) throws -> [Change] {
        guard old != new else { return [] }

        let oldPlatformNames = Set(old.map(\.name))
        let newPlatformNames = Set(new.map(\.name))

        var listOfChanges = [String]()

        let added = newPlatformNames.subtracting(oldPlatformNames)
        let removed = oldPlatformNames.subtracting(newPlatformNames)
        let consistent = oldPlatformNames.intersection(newPlatformNames)

        listOfChanges += added.compactMap { platformName in
            guard let addedPlatform = new.first(where: { $0.name == platformName }) else { return nil }
            return "Added \(addedPlatform.description)"
        }

        listOfChanges += consistent.compactMap { platformName in
            guard
                let newPlatform = new.first(where: { $0.name == platformName }),
                let oldPlatform = old.first(where: { $0.name == platformName }),
                newPlatform.description != oldPlatform.description
            else { return nil }

            return "Changed from \(oldPlatform.description) to \(newPlatform.description)"
        }

        listOfChanges += removed.compactMap { platformName in
            guard let removedPlatform = old.first(where: { $0.name == platformName }) else { return nil }
            return "Removed \(removedPlatform.description)"
        }

        let oldPlatformsString = old.map { "\($0.description)" }.joined(separator: ", ")
        let newPlatformsString = new.map { "\($0.description)" }.joined(separator: ", ")

        return [.init(
            changeType: .modification(
                oldDescription: "platforms: [\(oldPlatformsString)]",
                newDescription: "platforms: [\(newPlatformsString)]"
            ),
            parentPath: Constants.packageFileName,
            listOfChanges: listOfChanges
        )]
    }

    // MARK: - Products

    private func analyzeProducts(
        old: [SwiftPackageDescription.Product],
        new: [SwiftPackageDescription.Product]
    ) throws -> [Change] {
        guard old != new else { return [] }

        let oldProductNames = Set(old.map(\.name)).filter { $0 != "_AllTargets" }
        let newProductNames = Set(new.map(\.name)).filter { $0 != "_AllTargets" }

        let added = newProductNames.subtracting(oldProductNames)
        let removed = oldProductNames.subtracting(newProductNames)
        let consistent = Set(oldProductNames).intersection(Set(newProductNames))

        var changes = [Change]()

        changes += added.compactMap { addition in
            guard let addedProduct = new.first(where: { $0.name == addition }) else { return nil }
            return .init(
                changeType: .addition(description: addedProduct.description),
                parentPath: Constants.packageFileName(child: "products")
            )
        }

        try consistent.forEach { productName in
            guard
                let oldProduct = old.first(where: { $0.name == productName }),
                let newProduct = new.first(where: { $0.name == productName })
            else { return }

            changes += try analyzeProduct(
                old: oldProduct,
                new: newProduct
            )
        }

        changes += removed.compactMap { removal in
            guard let removedProduct = old.first(where: { $0.name == removal }) else { return nil }
            return .init(
                changeType: .removal(description: removedProduct.description),
                parentPath: Constants.packageFileName(child: "products")
            )
        }

        return changes
    }

    private func analyzeProduct(
        old oldProduct: SwiftPackageDescription.Product,
        new newProduct: SwiftPackageDescription.Product
    ) throws -> [Change] {
        guard oldProduct != newProduct else { return [] }

        let oldTargetNames = Set(oldProduct.targets)
        let newTargetNames = Set(newProduct.targets)

        let added = newTargetNames.subtracting(oldTargetNames)
        let removed = oldTargetNames.subtracting(newTargetNames)

        var listOfChanges = [String]()
        listOfChanges += added.map { "Added target \"\($0)\"" }
        listOfChanges += removed.map { "Removed target \"\($0)\"" }

        return [.init(
            changeType: .modification(
                oldDescription: oldProduct.description,
                newDescription: newProduct.description
            ),
            parentPath: Constants.packageFileName(child: "products"),
            listOfChanges: listOfChanges
        )]
    }

    // MARK: - Targets

    private func analyzeTargets(
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
        
        // MARK: Target Resources
        
        let oldResourcePaths = Set((oldTarget.resources?.map(\.path) ?? []).map { $0.trimmingPrefix(oldProjectBasePath) })
        let newResourcePaths = Set((newTarget.resources?.map(\.path) ?? []).map { $0.trimmingPrefix(newProjectBasePath) })
        
        let addedResourcePaths = newResourcePaths.subtracting(oldResourcePaths)
        let consistentResourcePaths = oldResourcePaths.intersection(newResourcePaths)
        let removedResourcePaths = oldResourcePaths.subtracting(newResourcePaths)
        
        // MARK: Target Dependencies

        let oldTargetDependencies = Set(oldTarget.targetDependencies ?? [])
        let newTargetDependencies = Set(newTarget.targetDependencies ?? [])

        let addedTargetDependencies = newTargetDependencies.subtracting(oldTargetDependencies)
        let removedTargetDependencies = oldTargetDependencies.subtracting(newTargetDependencies)
        
        // MARK: Product Dependencies

        let oldProductDependencies = Set(oldTarget.productDependencies ?? [])
        let newProductDependencies = Set(newTarget.productDependencies ?? [])

        let addedProductDependencies = newProductDependencies.subtracting(oldProductDependencies)
        let removedProductDependencies = oldProductDependencies.subtracting(newProductDependencies)

        // MARK: Compiling list of changes
        
        var listOfChanges = [String]()
        
        listOfChanges += addedResourcePaths.compactMap { path in
            guard let resource = newTarget.resources?.first(where: { $0.path == path }) else { return nil }
            return "Added resource \(resource.description)"
        }
        
        listOfChanges += consistentResourcePaths.compactMap { path in
            guard
                let newResource = newTarget.resources?.first(where: { $0.path == path }),
                let oldResource = oldTarget.resources?.first(where: { $0.path == path })
            else { return nil }
            
            return "Changed resource from `\(oldResource.description)` to `\(newResource.description)`"
        }
        
        listOfChanges += removedResourcePaths.compactMap { path in
            guard let resource = oldTarget.resources?.first(where: { $0.path == path }) else { return nil }
            return "Removed resource \(resource.description)"
        }
        
        listOfChanges += addedTargetDependencies.map { "Added dependency .target(name: \"\($0)\")" }
        listOfChanges += addedProductDependencies.map { "Added dependency .product(name: \"\($0)\", ...)" }

        if oldTarget.path != newTarget.path {
            listOfChanges += ["Changed path from \"\(oldTarget.path)\" to \"\(newTarget.path)\""]
        }

        if oldTarget.type != newTarget.type {
            listOfChanges += ["Changed type from `.\(oldTarget.type.description)` to `.\(newTarget.type.description)`"]
        }

        listOfChanges += removedTargetDependencies.map { "Removed dependency .target(name: \"\($0)\")" }
        listOfChanges += removedProductDependencies.map { "Removed dependency .product(name: \"\($0)\", ...)" }

        
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

    // MARK: - Dependencies

    private func analyzeDependencies(
        old: [SwiftPackageDescription.Dependency],
        new: [SwiftPackageDescription.Dependency]
    ) throws -> [Change] {
        guard old != new else { return [] }

        let oldDependencies = Set(old.map(\.identity))
        let newDependencies = Set(new.map(\.identity))

        let addedDependencies = newDependencies.subtracting(oldDependencies)
        let removedDependencies = oldDependencies.subtracting(newDependencies)
        let consistentDependencies = oldDependencies.intersection(newDependencies)

        var changes = [Change]()

        changes += addedDependencies.compactMap { addition in
            guard let addedDependency = new.first(where: { $0.identity == addition }) else { return nil }
            return .init(
                changeType: .addition(description: addedDependency.description),
                parentPath: Constants.packageFileName(child: "dependencies")
            )
        }

        try consistentDependencies.forEach { dependencyIdentity in
            guard
                let oldDependency = old.first(where: { $0.identity == dependencyIdentity }),
                let newDependency = new.first(where: { $0.identity == dependencyIdentity })
            else { return }

            changes += try analyzeDependency(
                oldDependency: oldDependency,
                newDependency: newDependency
            )
        }

        changes += removedDependencies.compactMap { addition in
            guard let removedDependency = old.first(where: { $0.identity == addition }) else { return nil }
            return .init(
                changeType: .removal(description: removedDependency.description),
                parentPath: Constants.packageFileName(child: "dependencies")
            )
        }

        return changes
    }

    private func analyzeDependency(
        oldDependency: SwiftPackageDescription.Dependency,
        newDependency: SwiftPackageDescription.Dependency
    ) throws -> [Change] {
        guard oldDependency != newDependency else { return [] }

        return [.init(
            changeType: .modification(
                oldDescription: oldDependency.description,
                newDescription: newDependency.description
            ),
            parentPath: Constants.packageFileName(child: "dependencies"),
            listOfChanges: [] // TODO: Improvement: Provide a `listOfChanges`
        )]
    }

    // MARK: - Tools Version

    private func analyzeToolsVersion(
        old: String,
        new: String
    ) throws -> [Change] {
        guard old != new else { return [] }

        return [.init(
            changeType: .modification(
                oldDescription: "// swift-tools-version: \(old)",
                newDescription: "// swift-tools-version: \(new)"
            ),
            parentPath: Constants.packageFileName
        )]
    }
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        var trimmed = self
        trimmed.trimPrefix(prefix)
        return trimmed
    }
}
