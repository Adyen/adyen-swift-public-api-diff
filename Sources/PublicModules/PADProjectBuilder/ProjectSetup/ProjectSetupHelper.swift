import Foundation

import PADCore
import PADLogging

import ShellModule
import FileHandlingModule

/// Helps setting up the project by:
/// - Copying project files into a working directory (and skipping unwanted files)
/// - Fetching a remote project (if applicable)
struct ProjectSetupHelper: ProjectSetupHelping {
    
    let workingDirectoryPath: String
    let shell: any ShellHandling
    let randomStringGenerator: any RandomStringGenerating
    let fileHandler: any FileHandling
    let logger: (any PADLogging)?
    
    init(
        workingDirectoryPath: String,
        randomStringGenerator: any RandomStringGenerating = RandomStringGenerator(),
        shell: any ShellHandling = Shell(),
        fileHandler: any FileHandling = FileManager.default,
        logger: (any PADLogging)?
    ) {
        self.workingDirectoryPath = workingDirectoryPath
        self.randomStringGenerator = randomStringGenerator
        self.shell = shell
        self.fileHandler = fileHandler
        self.logger = logger
    }
    
    func setup(
        _ projectSource: PADProjectSource,
        projectType: PADProjectType
    ) async throws -> URL {
        try await Task {
            let checkoutPath = workingDirectoryPath + "\(randomStringGenerator.generateRandomString())"
            switch projectSource {
            case .local(let path):
                shell.execute("cp -a '\(path)' '\(checkoutPath)'")
            case .git(let branch, let repository):
                let git = Git(shell: shell, fileHandler: fileHandler, logger: logger)
                try git.clone(repository, at: branch, targetDirectoryPath: checkoutPath)
            }
            
            filterProjectFiles(at: checkoutPath, for: projectType)
            return URL(filePath: checkoutPath)
        }.value
    }
    
    func filterProjectFiles(at checkoutPath: String, for projectType: PADProjectType) {
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
        oldSource: PADProjectSource,
        newSource: PADProjectSource,
        projectType: PADProjectType
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

private extension PADProjectType {
    
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
