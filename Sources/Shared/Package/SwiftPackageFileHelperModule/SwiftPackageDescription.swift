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

    package var projectBasePath: String = ""
    
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
        ".\(name)(\(version))"
    }
}

package extension SwiftPackageDescription {

    struct Product: Codable, Equatable, Hashable {

        // TODO: Add `type` property

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
        package let exact: [String]?
        package let range: [[String: String]]?
        package let branch: [String]?
        package let revision: [String]?
    }
}

extension SwiftPackageDescription.Dependency.Requirement: CustomStringConvertible {

    package var description: String {
        if let version = exact?.first {
            return "exact: \"\(version)\""
        }
        
        if let lowerUpper = range?.first, let lower = lowerUpper["lower_bound"], let upper = lowerUpper["upper_bound"] {
            return "\"\(lower)\"..<\"\(upper)\""
        }
        
        if let branch = branch?.first {
            return "branch: \"\(branch)\""
        }
        
        if let revision = revision?.first {
            return "revision: \"\(revision)\""
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
            case executable = "executable"
        }

        package let name: String
        package let type: TargetType
        package let path: String
        package let moduleType: ModuleType

        /// `.product(name: ...)` dependency
        package let productDependencies: [String]?
        /// `.target(name: ...) dependency
        package let targetDependencies: [String]?
        /// The resources used by the Target
        package let resources: [Resource]?
        
        // Ignoring following properties for now as they are not handled in the `PackageAnalyzer`
        // and thus would produce changes that are not visible
        //
        // let productMemberships: [String]?
        // let sources: [String]

        init(
            name: String,
            type: TargetType,
            path: String,
            moduleType: ModuleType,
            productDependencies: [String]? = nil,
            targetDependencies: [String]? = nil,
            resources: [Resource]? = nil
        ) {
            self.name = name
            self.type = type
            self.path = path
            self.moduleType = moduleType
            self.productDependencies = productDependencies
            self.targetDependencies = targetDependencies
            self.resources = resources
        }

        enum CodingKeys: String, CodingKey {
            case moduleType = "module_type"
            case name
            case productDependencies = "product_dependencies"
            case targetDependencies = "target_dependencies"
            case type
            case path
            case resources
        }
    }
}

extension SwiftPackageDescription.Target.TargetType: CustomStringConvertible {

    package var description: String {
        switch self {
        case .binary: "binaryTarget"
        case .library: "target"
        case .test: "testTarget"
        case .executable: "executableTarget"
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
        package let path: String
        package let rule: Rule
    }
}

extension SwiftPackageDescription.Target.Resource: CustomStringConvertible {

    package var description: String {
        return switch rule {
        case .copy: ".copy(\"\(path)\")"
        case .embeddInCode: ".embeddInCode(\"\(path)\")"
        case let .process(metadata):
            if let localization = metadata["localization"] {
                ".process(\"\(path)\", localization: \"\(localization)\")"
            } else {
                ".process(\"\(path)\")"
            }
        }
    }
}


package extension SwiftPackageDescription.Target.Resource {
    
    enum Rule: Codable, Equatable {
        case copy
        case embeddInCode
        case process([String: String])
        
        package init(from decoder: any Decoder) throws {
   
            enum RuleError: Error {
                case unsupportedRule
            }
            
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if (try? container.decode([String: String].self, forKey: .copy)) != nil {
                self = .copy
                return
            }
            
            if (try? container.decode([String: String].self, forKey: .embeddInCode)) != nil {
                self = .embeddInCode
                return
            }
            
            if let metadata = try? container.decode([String: String].self, forKey: .process) {
                self = .process(metadata)
                return
            }
            
            throw RuleError.unsupportedRule
        }
        
        package func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .copy:
                try container.encode([:] as [String: String], forKey: .copy)
            case .embeddInCode:
                try container.encode([:] as [String: String], forKey: .embeddInCode)
            case let .process(metadata):
                try container.encode(metadata, forKey: .process)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case copy
            case embeddInCode = "embed_in_code"
            case process
        }
    }
}
