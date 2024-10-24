import Foundation

import ShellModule
import FileHandlingModule
import PADLogging

public struct ProjectStatisticsAggregator {
    
    let shell: any ShellHandling
    let fileHandler: any FileHandling
    let logger: (any Logging)?
    
    public init(logger: (any Logging)? = nil) {
        self.init(
            shell: Shell(),
            fileHandler: FileManager.default,
            logger: logger
        )
    }
    
    init(
        shell: any ShellHandling,
        fileHandler: any FileHandling,
        logger: (any Logging)? = nil
    ) {
        self.shell = shell
        self.fileHandler = fileHandler
        self.logger = logger
    }
    
    public func aggregate(projectDirectory: URL) throws -> ProjectStatistics {

        let frameworks = try aggregateFrameworks(projectDirectory: projectDirectory)
        let objectFiles = try aggregateObjectFiles(projectDirectory: projectDirectory)
        let bundles = try aggregateBundles(projectDirectory: projectDirectory)
        
        return .init(statistics: frameworks + objectFiles + bundles)
    }
}

// MARK: - Privates

private extension ProjectStatisticsAggregator {
    
    private func aggregateFrameworks(projectDirectory: URL) throws -> [FrameworkStatistics] {
        let fileExtension = ".framework"
        let fileUrls = try fileUrls(forSuffix: fileExtension, projectDirectory: projectDirectory, isDirectory: true)
        
        return fileUrls.map { fileUrl in
            return FrameworkStatistics(
                fileName: fileUrl.lastPathComponent,
                content: content(at: fileUrl)
            )
        }
    }
    
    private func aggregateObjectFiles(projectDirectory: URL) throws -> [ObjectFileStatistics] {
        let fileExtension = ".o"
        let fileUrls = try fileUrls(forSuffix: fileExtension, projectDirectory: projectDirectory, isDirectory: false)
        
        return fileUrls.map { fileUrl in
            return ObjectFileStatistics(
                fileName: fileUrl.lastPathComponent,
                sizeInBytes: totalRecursiveSize(for: fileUrl)
            )
        }
    }
    
    private func aggregateBundles(projectDirectory: URL) throws -> [BundleStatistics] {
        let fileExtension = ".bundle"
        let fileUrls = try fileUrls(forSuffix: fileExtension, projectDirectory: projectDirectory, isDirectory: true)
        
        // TODO: If a framework is contained inside of a bundle we should ignore it as its size is already counted by the bundle itself)
        
        return fileUrls.map { fileUrl in
            return BundleStatistics(
                fileName: fileUrl.lastPathComponent,
                content: content(at: fileUrl)
            )
        }
    }
}

// MARK: - Convenience

private extension ProjectStatisticsAggregator {
    
    private func fileUrls(
        forSuffix suffix: String,
        projectDirectory: URL,
        isDirectory: Bool
    ) throws -> [URL] {
        
        let derivedDataProductsUrl = try derivedDataProductsUrl(for: projectDirectory)
        let command = "cd '\(derivedDataProductsUrl.path())'; find . -type \(isDirectory ? "d" : "f") -name '*\(suffix)'"
        return Shell().execute(command)
            .components(separatedBy: .newlines)
            .filter { $0.hasSuffix(suffix) }
            .map { derivedDataProductsUrl.appending(path: $0) }
    }
    
    func derivedDataProductsUrl(
        for projectDirectory: URL
    ) throws -> URL {
        
        let derivedDataProductsUrl = projectDirectory.appending(path: ".build/Build/Products/")
        
        guard fileHandler.fileExists(atPath: derivedDataProductsUrl.path()) else {
            throw FileHandlerError.pathDoesNotExist(path: derivedDataProductsUrl.path())
        }
        
        return derivedDataProductsUrl
    }
    
    private func content(at fileUrl: URL) -> [any StatisticsContent] {
        //sizeInBytes: totalRecursiveSize(for: fileUrl)
        guard let contents = try? fileHandler.contentsOfDirectory(atPath: fileUrl.path()).map({ fileUrl.appending(path: $0) }) else {
            return []
        }
        
        return contents.map { fileUrl in
            FileStatistics(fileName: fileUrl.lastPathComponent, sizeInBytes: totalRecursiveSize(for: fileUrl))
        }
    }
    
    func totalRecursiveSize(
        for fileUrl: URL
    ) -> SizeInBytes {
        
        if fileHandler.fileIsDirectory(atPath: fileUrl.path()) {
            guard let contents = try? fileHandler.contentsOfDirectory(atPath: fileUrl.path()) else { return 0 }
            return contents.reduce(0) { partialResult, fileName in
                partialResult + totalRecursiveSize(for: fileUrl.appending(path: fileName))
            }
        } else {
            return fileHandler.fileSize(atPath: fileUrl.path())
        }
    }
}
