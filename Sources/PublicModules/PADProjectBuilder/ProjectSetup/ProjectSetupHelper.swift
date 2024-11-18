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

/// Helps setting up the project by:
/// - Copying project files into a working directory (and skipping unwanted files)
/// - Fetching a remote project (if applicable)
struct ProjectSetupHelper: ProjectSetupHelping {
    
    let workingDirectoryPath: String
    let shell: any ShellHandling
    let randomStringGenerator: any RandomStringGenerating
    let fileHandler: any FileHandling
    let logger: (any Logging)?
    
    init(
        workingDirectoryPath: String,
        randomStringGenerator: any RandomStringGenerating = RandomStringGenerator(),
        shell: any ShellHandling = Shell(),
        fileHandler: any FileHandling = FileManager.default,
        logger: (any Logging)?
    ) {
        self.workingDirectoryPath = workingDirectoryPath
        self.randomStringGenerator = randomStringGenerator
        self.shell = shell
        self.fileHandler = fileHandler
        self.logger = logger
    }
    
    func setup(
        _ projectSource: ProjectSource,
        projectType: ProjectType
    ) async throws -> URL {
        try await Task {
            let checkoutPath = workingDirectoryPath + "\(randomStringGenerator.generateRandomString())"
            switch projectSource {
            case let .local(path):
                shell.execute("cp -a '\(path)' '\(checkoutPath)'")
            case let .git(branch, repository):
                let git = Git(shell: shell, fileHandler: fileHandler, logger: logger)
                try git.clone(repository, at: branch, targetDirectoryPath: checkoutPath)
            }
            
            filterProjectFiles(at: checkoutPath, for: projectType)
            return URL(filePath: checkoutPath)
        }.value
    }
    
    func filterProjectFiles(at checkoutPath: String, for projectType: ProjectType) {
        try? fileHandler.contentsOfDirectory(atPath: checkoutPath)
            .filter { !projectType.fileIsIncluded(filePath: $0) }
            .forEach { filePath in
                try? fileHandler.removeItem(atPath: "\(checkoutPath)/\(filePath)")
            }
    }
}

extension ProjectSetupHelper {
    
    /// Convenience method that calls into `setup(_:projectType:)` for the old and new source
    func setupProjects(
        oldSource: ProjectSource,
        newSource: ProjectSource,
        projectType: ProjectType
    ) async throws -> (old: URL, new: URL) {
        let projectSetupHelper = ProjectSetupHelper(
            workingDirectoryPath: workingDirectoryPath,
            logger: logger
        )
        
        // async let to make them perform in parallel
        async let newProjectDirectoryPath = try projectSetupHelper.setup(newSource, projectType: projectType)
        async let oldProjectDirectoryPath = try projectSetupHelper.setup(oldSource, projectType: projectType)
        
        return try await (oldProjectDirectoryPath, newProjectDirectoryPath)
    }
}

private extension ProjectType {
    
    var excludedFileSuffixes: [String] {
        switch self {
        case .swiftPackage:
            [".xcodeproj", ".xcworkspace"]
        case .xcodeProject:
            ["Package.swift"]
        }
    }
    
    func fileIsIncluded(filePath: String) -> Bool {
        for excludedFileSuffix in excludedFileSuffixes {
            if filePath.hasSuffix(excludedFileSuffix) { return false }
        }
        return true
    }
}
