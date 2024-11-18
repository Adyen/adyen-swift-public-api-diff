//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// The object representation of a `Package.swift` file
///
/// See: [PackageDescription](https://docs.swift.org/package-manager/PackageDescription/index.html) & [PackageDescriptionSerialization](https://github.com/swiftlang/swift-package-manager/blob/main/Sources/PackageDescription/PackageDescriptionSerialization.swift)
package struct SwiftPackageDescription: Codable, Equatable {
    
    package let name: String
    package let platforms: [Platform]
    package let defaultLocalization: String?
    
    package let targets: [Target]
    package let products: [Product]
    package let dependencies: [Dependency]
    
    package let toolsVersion: String
    
    package var warnings = [String]()
    
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
    
    package struct Platform: Codable, Equatable, Hashable {
        
        package let name: String
        package let version: String
    }
}

extension SwiftPackageDescription.Platform: CustomStringConvertible {
    
    package var description: String {
        "\(name)(\(version))"
    }
}

package extension SwiftPackageDescription {
    
    struct Product: Codable, Equatable, Hashable {
        
        // TODO: Add `rule` property
        
        package let name: String
        package let targets: [String]
    }
}

extension SwiftPackageDescription.Product: CustomStringConvertible {
    
    package var description: String {
        let targetsDescription = targets.map { "\"\($0)\"" }.joined(separator: ", ")
        return ".library(name: \"\(name)\", targets: [\(targetsDescription)])"
    }
}

package extension SwiftPackageDescription {
    
    struct Dependency: Codable, Equatable {
        
        package let identity: String
        package let requirement: Requirement
        package let type: String
        package let url: String?
    }
}

extension SwiftPackageDescription.Dependency: CustomStringConvertible {
    
    package var description: String {
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

package extension SwiftPackageDescription.Dependency {
    
    struct Requirement: Codable, Equatable {
        
        // TODO: Which other requirements exist?
        
        package let exact: [String]?
    }
}

extension SwiftPackageDescription.Dependency.Requirement: CustomStringConvertible {
    
    package var description: String {
        if let exactVersion = exact?.first {
            return "exact: \"\(exactVersion)\""
        }
        
        return "UNKNOWN_REQUIREMENT"
    }
}

package extension SwiftPackageDescription {
    
    struct Target: Codable, Equatable {
        
        package enum ModuleType: String, Codable, Equatable {
            case swiftTarget = "SwiftTarget"
            case binaryTarget = "BinaryTarget"
            case clangTarget = "ClangTarget"
        }
        
        package enum TargetType: String, Codable, Equatable {
            case library = "library"
            case binary = "binary"
            case test = "test"
        }
        
        package let name: String
        package let type: TargetType
        package let path: String
        package let moduleType: ModuleType
        
        /// `.product(name: ...)` dependency
        package let productDependencies: [String]?
        /// `.target(name: ...) dependency
        package let targetDependencies: [String]?
        
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
    
    package var description: String {
        switch self {
        case .binary: "binaryTarget"
        case .library: "target"
        case .test: "testTarget"
        }
    }
}

extension SwiftPackageDescription.Target: CustomStringConvertible {
    
    package var description: String {
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

package extension SwiftPackageDescription.Target {
    
    struct Resource: Codable, Equatable {
        
        // TODO: Add `rule` property
        
        package let path: String
    }
}
