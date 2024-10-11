//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADFileHandling
import PADShell
import PADLogging

enum SwiftPackageFileHelperError: LocalizedError {
    case packageDescriptionError(_ description: String)
    case couldNotGeneratePackageDescription
    case couldNotConsolidateTargetsInPackageFile
    
    var errorDescription: String? {
        switch self {
        case .couldNotGeneratePackageDescription:
            "Could not generate package description"
        case let .packageDescriptionError(description):
            description
        case .couldNotConsolidateTargetsInPackageFile:
            "Could not consolidate all targets into a single product"
        }
    }
}

struct SwiftPackageFileHelper {
    
    private let fileHandler: FileHandling
    private let shell: any ShellHandling
    private let logger: (any Logging)?
    
    public init(
        fileHandler: FileHandling,
        shell: any ShellHandling,
        logger: (any Logging)?
    ) {
        self.fileHandler = fileHandler
        self.shell = shell
        self.logger = logger
    }
    
    public static func packagePath(for projectDirectoryPath: String) -> String {
        projectDirectoryPath.appending("/Package.swift")
    }
    
    public func availableTargets(
        at projectDirectoryPath: String,
        moduleType: SwiftPackageDescription.Target.ModuleType? = nil,
        targetType: SwiftPackageDescription.Target.TargetType? = nil
    ) throws -> Set<String> {
        
        var targets = try packageDescription(at: projectDirectoryPath).targets
        
        if let moduleType {
            targets = targets.filter { $0.moduleType == moduleType }
        }
        
        if let targetType {
            targets = targets.filter { $0.type == targetType }
        }
        
        return Set(targets.map(\.name))
    }
    
    public func packageDescription(at projectDirectoryPath: String) throws -> SwiftPackageDescription {
        try generatePackageDescription(at: projectDirectoryPath)
    }
    
    /// Inserts a new library into the targets section containing all targets from the target section
    public func preparePackageWithConsolidatedLibrary(
        named consolidatedLibraryName: String,
        at projectDirectoryPath: String
    ) throws {
        
        let packagePath = Self.packagePath(for: projectDirectoryPath)
        let packageContent = try fileHandler.loadString(from: packagePath)
        let targets = try availableTargets(
            at: projectDirectoryPath,
            moduleType: .swiftTarget,
            targetType: .library
        )
        
        let consolidatedEntry = consolidatedLibraryEntry(consolidatedLibraryName, from: targets.sorted())
        let updatedPackageContent = try updatedContent(packageContent, with: consolidatedEntry)
        
        // Write the updated content back to the file
        try fileHandler.write(updatedPackageContent, to: packagePath)
    }
}

// MARK: - Privates

// MARK: Generate Package Description

private extension SwiftPackageFileHelper {
    
    func generatePackageDescription(at projectDirectoryPath: String) throws -> SwiftPackageDescription {
        
        let result = try loadPackageDescription(projectDirectoryPath: projectDirectoryPath)
        
        let newLine = "\n"
        let errorTag = "error: "
        let warningTag = "warning: "
        
        var packageDescriptionLines = result.components(separatedBy: newLine)
        var warnings = [String]()
        
        while let firstLine = packageDescriptionLines.first {
            
            // If there are warnings/errors when generating the description
            // there are non-json lines added on the top of the result
            // That we have to get rid of first to generate the description object
            
            if firstLine.starts(with: errorTag) {
                throw SwiftPackageFileHelperError.packageDescriptionError(result)
            }
            
            if firstLine.starts(with: warningTag) {
                let directoryTag = "'\(URL(filePath: projectDirectoryPath).lastPathComponent)': "
                let warning = firstLine
                    .replacingOccurrences(of: warningTag, with: "")
                    .replacingOccurrences(of: directoryTag, with: "", options: .caseInsensitive)
                warnings += [warning]
            }
            
            if 
                firstLine.starts(with: "{"),
                let packageDescriptionData = packageDescriptionLines.joined(separator: newLine).data(using: .utf8)
            {
                return try decodePackageDescription(from: packageDescriptionData, warnings: warnings)
            }
            
            packageDescriptionLines.removeFirst()
        }
        
        throw SwiftPackageFileHelperError.couldNotGeneratePackageDescription
    }
    
    func loadPackageDescription(
        projectDirectoryPath: String
    ) throws -> String {
        let command = [
            "cd \(projectDirectoryPath);",
            "swift package describe --type json"
        ]
        
        return shell.execute(command.joined(separator: " "))
    }
    
    func decodePackageDescription(from packageDescriptionData: Data, warnings: [String]) throws -> SwiftPackageDescription {
        var packageDescription = try JSONDecoder().decode(SwiftPackageDescription.self, from: packageDescriptionData)
        packageDescription.warnings = warnings
        return packageDescription
    }
}

// MARK: Update Package Content

private extension SwiftPackageFileHelper {
    
    /// Generates a library entry from the name and available target names to be inserted into the `Package.swift` file
    func consolidatedLibraryEntry(
        _ name: String,
        from availableTargets: [String]
    ) -> String {
        """
        
                .library(
                    name: "\(name)",
                    targets: [\(availableTargets.map { "\"\($0)\"" }.joined(separator: ", "))]
                ),
        """
    }
    
    /// Generates the updated content for the `Package.swift` adding the consolidated library entry (containing all targets) in the products section
    func updatedContent(
        _ packageContent: String,
        with consolidatedEntry: String
    ) throws -> String {
        // Update the Package.swift content
        var updatedContent = packageContent
        if let productsRange = packageContent.range(of: "products: [", options: .caseInsensitive) {
            updatedContent.insert(contentsOf: consolidatedEntry, at: productsRange.upperBound)
        } else {
            throw SwiftPackageFileHelperError.couldNotConsolidateTargetsInPackageFile
        }
        return updatedContent
    }
}