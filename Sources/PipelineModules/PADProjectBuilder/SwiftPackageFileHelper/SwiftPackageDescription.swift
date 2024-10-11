//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

// See: https://docs.swift.org/package-manager/PackageDescription/index.html
// See: https://github.com/swiftlang/swift-package-manager/blob/main/Sources/PackageDescription/PackageDescriptionSerialization.swift

struct SwiftPackageDescription: Codable, Equatable {
    
    let name: String
    let platforms: [Platform]
    let defaultLocalization: String?
    
    let targets: [Target]
    let products: [Product]
    let dependencies: [Dependency]
    
    public let toolsVersion: String
    
    public var warnings = [String]()
    
    init(
        defaultLocalization: String?,
        name: String,
        platforms: [Platform] = [],
        products: [Product] = [],
        targets: [Target] = [],
        dependencies: [Dependency] = [],
        toolsVersion: String,
        warnings: [String] = []
    ) {
        self.defaultLocalization = defaultLocalization
        self.name = name
        self.platforms = platforms
        self.products = products
        self.targets = targets
        self.dependencies = dependencies
        self.toolsVersion = toolsVersion
        self.warnings = warnings
    }
    
    enum CodingKeys: String, CodingKey {
        case defaultLocalization = "default_localization"
        case name
        case platforms
        case products
        case targets
        case dependencies
        case toolsVersion = "tools_version"
    }
}

extension SwiftPackageDescription {
    
    public struct Platform: Codable, Equatable, Hashable {
        
        public let name: String
        public let version: String
    }
}

extension SwiftPackageDescription.Platform: CustomStringConvertible {
    
    public var description: String {
        "\(name)(\(version))"
    }
}

extension SwiftPackageDescription {
    
    public struct Product: Codable, Equatable, Hashable {
        
        // TODO: Add `rule` property
        
        public let name: String
        public let targets: [String]
    }
}

extension SwiftPackageDescription.Product: CustomStringConvertible {
    
    public var description: String {
        let targetsDescription = targets.map { "\"\($0)\"" }.joined(separator: ", ")
        return ".library(name: \"\(name)\", targets: [\(targetsDescription)])"
    }
}

extension SwiftPackageDescription {
    
    public struct Dependency: Codable, Equatable {
        
        public let identity: String
        public let requirement: Requirement
        public let type: String
        public let url: String?
    }
}

extension SwiftPackageDescription.Dependency: CustomStringConvertible {
    
    public var description: String {
        var description = ".package("
        
        var fields = [String]()
        
        if let url {
            fields += ["url: \"\(url)\""]
        }
        
        fields += [requirement.description]
        
        description += fields.joined(separator: ", ")
        
        description += ")"
        return description
    }
}

extension SwiftPackageDescription.Dependency {
    
    public struct Requirement: Codable, Equatable {
        
        // TODO: Which other requirements exist?
        
        public let exact: [String]?
    }
}

extension SwiftPackageDescription.Dependency.Requirement: CustomStringConvertible {
    
    public var description: String {
        if let exactVersion = exact?.first {
            return "exact: \"\(exactVersion)\""
        }
        
        return "UNKNOWN_REQUIREMENT"
    }
}

extension SwiftPackageDescription {
    
    public struct Target: Codable, Equatable {
        
        public enum ModuleType: String, Codable, Equatable {
            case swiftTarget = "SwiftTarget"
            case binaryTarget = "BinaryTarget"
            case clangTarget = "ClangTarget"
        }
        
        public enum TargetType: String, Codable, Equatable {
            case library = "library"
            case binary = "binary"
            case test = "test"
        }
        
        public let name: String
        public let type: TargetType
        public let path: String
        public let moduleType: ModuleType
        
        /// `.product(name: ...)` dependency
        public let productDependencies: [String]?
        /// `.target(name: ...) dependency
        public let targetDependencies: [String]?
        
        // Ignoring following properties for now as they are not handled in the `PackageAnalyzer`
        // and thus would produce changes that are not visible
        //
        // let productMemberships: [String]?
        // let sources: [String]
        // let resources: [Resource]?
        
        public init(
            name: String,
            type: TargetType,
            path: String,
            moduleType: ModuleType,
            productDependencies: [String]? = nil,
            targetDependencies: [String]? = nil
        ) {
            self.name = name
            self.type = type
            self.path = path
            self.moduleType = moduleType
            self.productDependencies = productDependencies
            self.targetDependencies = targetDependencies
        }
        
        enum CodingKeys: String, CodingKey {
            case moduleType = "module_type"
            case name
            case productDependencies = "product_dependencies"
            case targetDependencies = "target_dependencies"
            case type
            case path
        }
    }
}

extension SwiftPackageDescription.Target.TargetType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .binary: "binaryTarget"
        case .library: "target"
        case .test: "testTarget"
        }
    }
}

extension SwiftPackageDescription.Target: CustomStringConvertible {
    
    public var description: String {
        var description = ".\(type.description)(name: \"\(name)\""
        
        var dependencyDescriptions = [String]()
        
        if let targetDependenciesDescriptions = targetDependencies?.map({ ".target(name: \"\($0)\")" }) {
            dependencyDescriptions += targetDependenciesDescriptions
        }
        
        if let productDependenciesDescriptions = productDependencies?.map({ ".product(name: \"\($0)\", ...)" }) {
            dependencyDescriptions += productDependenciesDescriptions
        }
        
        if !dependencyDescriptions.isEmpty {
             // `, dependencies: [.target(name: ...), .target(name: ...), .product(name: ...), ...]`
            description += ", dependencies: [\(dependencyDescriptions.joined(separator: ", "))]"
        }
        
        description += ", path: \"\(path)\""
        
        description += ")"
        
        return description
    }
}

extension SwiftPackageDescription.Target {
    
    struct Resource: Codable, Equatable {
        
        // TODO: Add `rule` property
        
        let path: String
    }
}
