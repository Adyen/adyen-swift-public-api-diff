// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "public-api-diff",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "public-api-diff",
            targets: ["public-api-diff"]
        ),
        .library(
            name: "SwiftInterfaceDiff",
            targets: [
                "PADSwiftInterfaceDiff",
                "PADOutputGenerator"
            ]
        ),
        .library(
            name: "PublicApiDiff",
            targets: [
                "PADProjectBuilder",
                "PADSwiftInterfaceDiff",
                "PADOutputGenerator"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.6")
    ],
    targets: [
        
        // MARK: - Executable Targets
        
        .executableTarget(
            name: "public-api-diff",
            dependencies: [
                "PADCore",
                "PADLogging",
                "PADOutputGenerator",
                "PADFileHandling",
                "PADProjectBuilder",
                "PADSwiftInterfaceDiff",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/ExecutableTargets/CommandLineTool"
        ),
        
        // MARK: - Shared Helper Modules
        
        .target(
            name: "PADCore",
            path: "Sources/SharedHelperModules/PADCore"
        ),
        .target(
            name: "PADFileHandling",
            path: "Sources/SharedHelperModules/PADFileHandling"
        ),
        .target(
            name: "PADShell",
            path: "Sources/SharedHelperModules/PADShell"
        ),
        .target(
            name: "PADLogging",
            dependencies: ["PADFileHandling"],
            path: "Sources/SharedHelperModules/PADLogging"
        ),
        
        // MARK: - Pipeline Modules
        
        .target(
            name: "PADSwiftInterfaceDiff",
            dependencies: [
                "PADCore",
                "PADFileHandling",
                "PADLogging",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/PipelineModules/PADSwiftInterfaceDiff"
        ),
        .target(
            name: "PADProjectBuilder",
            dependencies: [
                "PADCore",
                "PADFileHandling",
                "PADLogging",
                "PADShell"
            ],
            path: "Sources/PipelineModules/PADProjectBuilder"
        ),
        .target(
            name: "PADOutputGenerator",
            dependencies: ["PADCore"],
            path: "Sources/PipelineModules/PADOutputGenerator"
        ),
        
        // MARK: - Test Targets
        
        .testTarget(
            name: "UnitTests",
            dependencies: [
                "public-api-diff"
            ],
            resources: [
                // Copy Tests/ExampleTests/Resources directories as-is.
                // Use to retain directory structure.
                // Will be at top level in bundle.
                .copy("Resources/expected-reference-changes.md")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["public-api-diff"],
            resources: [
                // Copy Tests/ExampleTests/Resources directories as-is.
                // Use to retain directory structure.
                // Will be at top level in bundle.
                .copy("Resources/expected-reference-changes-swift-interface-private.md"),
                .copy("Resources/expected-reference-changes-swift-interface-public.md")
            ]
        )
    ]
)
