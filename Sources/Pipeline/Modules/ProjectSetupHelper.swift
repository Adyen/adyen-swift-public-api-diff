import Foundation

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
            case .local(let path):
                shell.execute("cp -a '\(path)' '\(checkoutPath)'")
            case .remote(let branch, let repository):
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
    
    struct ProjectDirectories {
        let old: URL
        let new: URL
    }
    
    func setupProjects(
        oldSource: ProjectSource,
        newSource: ProjectSource,
        projectType: ProjectType
    ) async throws -> ProjectDirectories {
        let projectSetupHelper = ProjectSetupHelper(
            workingDirectoryPath: workingDirectoryPath,
            logger: logger
        )
        
        // async let to make them perform in parallel
        async let newProjectDirectoryPath = try projectSetupHelper.setup(newSource, projectType: projectType)
        async let oldProjectDirectoryPath = try projectSetupHelper.setup(oldSource, projectType: projectType)
        
        return try await .init(old: oldProjectDirectoryPath, new: newProjectDirectoryPath)
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
