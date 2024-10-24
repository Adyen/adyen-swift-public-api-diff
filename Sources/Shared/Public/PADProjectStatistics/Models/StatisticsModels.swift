import Foundation

public typealias SizeInBytes = Int

public extension SizeInBytes {
    
    var bytesFormattedAsMB: String {
        let megabytes = Double(self) / (1024*1024)
        return String(format: "%.2f MB", megabytes)
    }
    
    var bytesFormattedAsKB: String {
        let kilobytes = Double(self) / (1024)
        return String(format: "%.2f KB", kilobytes)
    }
}

public protocol StatisticsContent {
    var name: String { get }
    var fileName: String { get }
    var sizeInBytes: SizeInBytes { get }
    
    // TODO: Add info about number of func/var/struct/class/...
    
    var content: [any StatisticsContent] { get }
}

public struct FileStatistics: StatisticsContent {
    public var name: String { fileName }
    public let fileName: String
    public let sizeInBytes: SizeInBytes
    public let content = [any StatisticsContent]()
}

public struct ObjectFileStatistics: StatisticsContent {
    
    static var fileExtension: String = ".o"
    public var name: String {
        let name = fileName.split(separator: "_").last.map { String($0) } ?? fileName
        return name.hasSuffix(Self.fileExtension) ? name.removingLast(Self.fileExtension.count) : name
    }
    public let fileName: String
    public let sizeInBytes: SizeInBytes
    public let content = [any StatisticsContent]()
    
    init(fileName: String, sizeInBytes: SizeInBytes) {
        self.fileName = fileName
        self.sizeInBytes = sizeInBytes
    }
}

public struct FrameworkStatistics: StatisticsContent {

    /*
     -r-xr-xr-x   1 ...  staff  638096 Oct 17 10:52 Adyen3DS2
     drwxr-xr-x  23 ...  staff     736 Oct 17 10:52 Adyen3DS2.bundle
     drwxr-xr-x  25 ...  staff     800 Oct 17 10:52 Headers
     -r--r--r--   1 ...  staff     756 Oct 17 10:52 Info.plist
     drwxr-xr-x   3 ...  staff      96 Oct 17 10:52 Modules
     -r--r--r--   1 ...  staff    1208 Oct 17 10:52 PrivacyInfo.xcprivacy
     drwxr-xr-x   3 ...  staff      96 Oct 17 10:52 _CodeSignature
     */
    
    static var fileExtension: String = ".framework"
    public var name: String {
        fileName.hasSuffix(Self.fileExtension) ? fileName.removingLast(Self.fileExtension.count) : fileName
    }
    public let fileName: String
    public var sizeInBytes: SizeInBytes { content.sizeInBytes }
    
    public let content: [any StatisticsContent]
}

public struct BundleStatistics: StatisticsContent {
    
    /*
     -rw-r--r--   1 ...  staff  506160 Oct 17 10:52 Assets.car
     -rw-r--r--   1 ...  staff     674 Oct 17 10:52 Info.plist
     -rw-r--r--   1 ...  staff   15948 Oct 17 10:52 custom-xcassets-template.stencil
     drwxr-xr-x   3 ...  staff      96 Oct 17 10:52 en.lproj
     -rw-r--r--   1 ...  staff     357 Oct 17 10:52 swiftgen.yml
     */
    
    static var fileExtension: String = ".bundle"
    public var name: String {
        let name = fileName.split(separator: "_").last.map { String($0) } ?? fileName
        return name.hasSuffix(Self.fileExtension) ? name.removingLast(Self.fileExtension.count) : name
    }
    public let fileName: String
    public var sizeInBytes: SizeInBytes { content.sizeInBytes }
    
    public let content: [any StatisticsContent]
}

public struct ProjectStatistics {
    
    public let statistics: [any StatisticsContent]
    
    public func statistics(forModule moduleName: String) -> [any StatisticsContent] {
        statistics.filter { $0.name == moduleName }
    }
    
    public var totalSize: SizeInBytes {
        statistics.reduce(0) { partialResult, statistics in
            partialResult + statistics.sizeInBytes
        }
    }
    
    public init(statistics: [any StatisticsContent]) {
        self.statistics = statistics
    }
}

// MARK: - Extensions

extension [any StatisticsContent] {
    public var sizeInBytes: SizeInBytes {
        reduce(0) { partialResult, statistics in
            partialResult + statistics.sizeInBytes
        }
    }
}

extension String {
    
    func removingLast(_ k: Int) -> String {
        var string = self
        string.removeLast(k)
        return string
    }
}
