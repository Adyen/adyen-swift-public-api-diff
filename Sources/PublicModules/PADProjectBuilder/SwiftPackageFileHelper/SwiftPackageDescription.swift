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
    
    let toolsVersion: String
    
    var warnings = [String]()
    
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
    
    struct Platform: Codable, Equatable, Hashable {
        
        let name: String
        let version: String
    }
}

extension SwiftPackageDescription.Platform: CustomStringConvertible {
    
    var description: String {
        "\(name)(\(version))"
    }
}

extension SwiftPackageDescription {
    
    struct Product: Codable, Equatable, Hashable {
        
        // TODO: Add `rule` property
        
        let name: String
        let targets: [String]
    }
}

extension SwiftPackageDescription.Product: CustomStringConvertible {
    
    var description: String {
        let targetsDescription = targets.map { "\"\($0)\"" }.joined(separator: ", ")
        return ".library(name: \"\(name)\", targets: [\(targetsDescription)])"
    }
}

extension SwiftPackageDescription {
    
    struct Dependency: Codable, Equatable {
        
        let identity: String
        let requirement: Requirement
        let type: String
        let url: String?
    }
}

extension SwiftPackageDescription.Dependency: CustomStringConvertible {
    
    var description: String {
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
    
    struct Requirement: Codable, Equatable {
        
        // TODO: Which other requirements exist?
        
        let exact: [String]?
    }
}

extension SwiftPackageDescription.Dependency.Requirement: CustomStringConvertible {
    
    var description: String {
        if let exactVersion = exact?.first {
            return "exact: \"\(exactVersion)\""
        }
        
        return "UNKNOWN_REQUIREMENT"
    }
}

extension SwiftPackageDescription {
    
    struct Target: Codable, Equatable {
        
        enum ModuleType: String, Codable, Equatable {
            case swiftTarget = "SwiftTarget"
            case binaryTarget = "BinaryTarget"
            case clangTarget = "ClangTarget"
        }
        
        enum TargetType: String, Codable, Equatable {
            case library = "library"
            case binary = "binary"
            case test = "test"
        }
        
        let name: String
        let type: TargetType
        let path: String
        let moduleType: ModuleType
        
        /// `.product(name: ...)` dependency
        let productDependencies: [String]?
        /// `.target(name: ...) dependency
        let targetDependencies: [String]?
        
        // Ignoring following properties for now as they are not handled in the `PackageAnalyzer`
        // and thus would produce changes that are not visible
        //
        // let productMemberships: [String]?
        // let sources: [String]
        // let resources: [Resource]?
        
        init(
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
    
    var description: String {
        switch self {
        case .binary: "binaryTarget"
        case .library: "target"
        case .test: "testTarget"
        }
    }
}

extension SwiftPackageDescription.Target: CustomStringConvertible {
    
    var description: String {
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