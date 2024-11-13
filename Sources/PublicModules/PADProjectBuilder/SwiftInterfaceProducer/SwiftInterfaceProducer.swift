//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

import PADCore
import PADLogging
import PADSwiftInterfaceFileLocator

import FileHandlingModule
import ShellModule
import SwiftPackageFileHelperModule

/// Allows building of the old & new project and returns the `.swiftinterface` files
struct SwiftInterfaceProducer {

    private typealias ProjectPreparationResult = (archiveScheme: String, schemesToCompare: [String])
    private typealias DerivedDataPaths = (new: String, old: String)

    let workingDirectoryPath: String
    let projectType: ProjectType
    let swiftInterfaceType: SwiftInterfaceType
    let fileHandler: any FileHandling
    let shell: any ShellHandling
    let logger: (any Logging)?

    /// Builds the projects and returns the `.swiftinterface` files
    func produceInterfaceFiles(
        oldProjectDirectory: URL,
        newProjectDirectory: URL
    ) async throws -> [SwiftInterfaceFile] {

        let newProjectDirectoryPath = newProjectDirectory.path()
        let oldProjectDirectoryPath = oldProjectDirectory.path()

        let projectPreparationResult = try prepareProjectsForArchiving(
            newProjectDirectoryPath: newProjectDirectoryPath,
            oldProjectDirectoryPath: oldProjectDirectoryPath
        )

        let derivedDataPaths = try await archiveProjects(
            newProjectDirectoryPath: newProjectDirectoryPath,
            oldProjectDirectoryPath: oldProjectDirectoryPath,
            scheme: projectPreparationResult.archiveScheme
        )

        return try locateInterfaceFiles(
            newDerivedDataPath: derivedDataPaths.new,
            oldDerivedDataPath: derivedDataPaths.old,
            schemes: projectPreparationResult.schemesToCompare
        )
    }
}

extension SwiftInterfaceProducer {

    /// Prepares the projects for archiving considering the project type
    ///
    /// - .swiftPackage
    ///   - Adds a library `_AllTargets` that contains all targets found inside targets list of the Package.swift
    ///
    /// - .xcodeProject:
    ///   - Nothing specific
    ///
    /// - Returns: `ProjectPreparationResult` containing the scheme to archive and sub-schemes that are included
    private func prepareProjectsForArchiving(
        newProjectDirectoryPath: String,
        oldProjectDirectoryPath: String
    ) throws -> ProjectPreparationResult {
        let archiveScheme: String
        let schemesToCompare: [String]

        switch projectType {
        case .swiftPackage:
            archiveScheme = "_AllTargets"
            let packageFileHelper = SwiftPackageFileHelper(fileHandler: fileHandler, shell: shell, logger: logger)
            try packageFileHelper
                .preparePackageWithConsolidatedLibrary(named: archiveScheme, at: newProjectDirectoryPath)
            try packageFileHelper
                .preparePackageWithConsolidatedLibrary(named: archiveScheme, at: oldProjectDirectoryPath)

            let newTargets = try Set(packageFileHelper.availableTargets(at: newProjectDirectoryPath))
            let oldTargets = try Set(packageFileHelper.availableTargets(at: oldProjectDirectoryPath))

            schemesToCompare = newTargets.intersection(oldTargets).sorted()

            if schemesToCompare.isEmpty {
                throw Error.noTargetFound
            }

        case let .xcodeProject(scheme):
            archiveScheme = scheme
            schemesToCompare = [scheme]
        }

        return (archiveScheme, schemesToCompare)
    }

    /// Archives the projects to produce `.swiftinterface` files
    /// - Parameters:
    ///   - newProjectDirectoryPath: The path to the "new" project directory
    ///   - oldProjectDirectoryPath: The path to the "old" project directory
    ///   - scheme: The scheme to archive
    /// - Returns: The old and new derived data path
    private func archiveProjects(
        newProjectDirectoryPath: String,
        oldProjectDirectoryPath: String,
        scheme: String
    ) async throws -> DerivedDataPaths {

        // We don't run them in parallel to not conflict with resolving dependencies concurrently

        let xcodeTools = XcodeTools(
            shell: shell,
            fileHandler: fileHandler,
            logger: logger
        )

        let newDerivedDataPath = try await xcodeTools.archive(
            projectDirectoryPath: newProjectDirectoryPath,
            scheme: scheme,
            projectType: projectType
        )
        let oldDerivedDataPath = try await xcodeTools.archive(
            projectDirectoryPath: oldProjectDirectoryPath,
            scheme: scheme,
            projectType: projectType
        )

        return (newDerivedDataPath, oldDerivedDataPath)
    }

    /// Locates the `.swiftinterface` files for the provided schemes within the derived data directories
    /// - Parameters:
    ///   - newDerivedDataPath: The "new" derived data directory path
    ///   - oldDerivedDataPath: The "old" derived data directory path
    ///   - schemesToCompare: The schemes/modules to find the `.swiftinterface` files for
    /// - Returns: A list of ``SwiftInterfaceFile``s
    private func locateInterfaceFiles(
        newDerivedDataPath: String,
        oldDerivedDataPath: String,
        schemes schemesToCompare: [String]
    ) throws -> [SwiftInterfaceFile] {
        logger?.log("🔎 Locating interface files for \(schemesToCompare.joined(separator: ", "))", from: String(describing: Self.self))

        let interfaceFileLocator = SwiftInterfaceFileLocator(fileHandler: fileHandler, shell: shell, logger: logger)
        return schemesToCompare.compactMap { scheme in
            do {
                let newSwiftInterfaceUrl = try interfaceFileLocator.locate(for: scheme, derivedDataPath: newDerivedDataPath, type: swiftInterfaceType)
                let oldSwiftInterfaceUrl = try interfaceFileLocator.locate(for: scheme, derivedDataPath: oldDerivedDataPath, type: swiftInterfaceType)
                return .init(name: scheme, oldFilePath: oldSwiftInterfaceUrl.path(), newFilePath: newSwiftInterfaceUrl.path())
            } catch {
                logger?.debug("👻 \(error.localizedDescription)", from: String(describing: Self.self))
                return nil
            }
        }
    }
}
