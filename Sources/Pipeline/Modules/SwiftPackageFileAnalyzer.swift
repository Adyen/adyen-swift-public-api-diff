//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

struct SwiftPackageFileAnalyzer: ProjectAnalyzing {
    
    let fileHandler: FileHandling
    let xcodeTools: XcodeTools
    
    init(
        fileHandler: FileHandling = FileManager.default,
        shell: ShellHandling = Shell(),
        logger: Logging?
    ) {
        self.fileHandler = fileHandler
        self.xcodeTools = XcodeTools(shell: shell, fileHandler: fileHandler, logger: logger)
    }
    
    func analyze(oldProjectUrl: URL, newProjectUrl: URL) throws -> ProjectAnalyzerResult {
        
        let oldProjectPath = oldProjectUrl.path()
        let newProjectPath = newProjectUrl.path()
        
        let oldPackagePath = PackageFileHelper.packagePath(for: oldProjectPath)
        let newPackagePath = PackageFileHelper.packagePath(for: newProjectPath)
        
        if fileHandler.fileExists(atPath: oldPackagePath), fileHandler.fileExists(atPath: newPackagePath) {
            let packageHelper = PackageFileHelper(
                fileHandler: fileHandler,
                xcodeTools: xcodeTools
            )
            
            return try analyze(
                old: packageHelper.packageDescription(at: oldProjectPath),
                new: packageHelper.packageDescription(at: newProjectPath)
            )
        } else {
            return .init(
                changes: [],
                warnings: []
            )
        }
    }
    
    private func analyze(
        old oldPackageDescription: SwiftPackageDescription,
        new newPackageDescription: SwiftPackageDescription
    ) throws -> ProjectAnalyzerResult {
        
        let oldLibraries = Set(oldPackageDescription.products.map(\.name))
        let newLibraries = Set(newPackageDescription.products.map(\.name))
        
        let removedLibaries = oldLibraries.subtracting(newLibraries)
        var packageChanges = [Change]()
        
        packageChanges += removedLibaries.map {
            .init(
                changeType: .removal(description: ".library(name: \"\($0)\", ...)"),
                parentPath: ""
            )
        }
        
        let addedLibraries = newLibraries.subtracting(oldLibraries)
        packageChanges += addedLibraries.map {
            .init(
                changeType: .addition(description: ".library(name: \"\($0)\", ...)"),
                parentPath: ""
            )
        }
        
        return .init(
            changes: packageChanges,
            warnings: newPackageDescription.warnings
        )
    }
}
