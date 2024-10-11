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
                "PADProjectBuilder",
                "PADSwiftInterfaceDiff",
                "PADOutputGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/ExecutableTargets/CommandLineTool"
        ),
        
        // MARK: - Public Modules
        
        .target(
            name: "PADSwiftInterfaceDiff",
            dependencies: [
                "PADCore",
                "FileHandlingModule",
                "PADLogging",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/PublicModules/PADSwiftInterfaceDiff"
        ),
        .target(
            name: "PADProjectBuilder",
            dependencies: [
                "PADCore",
                "FileHandlingModule",
                "PADLogging",
                "ShellModule"
            ],
            path: "Sources/PublicModules/PADProjectBuilder"
        ),
        .target(
            name: "PADOutputGenerator",
            dependencies: ["PADCore"],
            path: "Sources/PublicModules/PADOutputGenerator"
        ),
        
        // MARK: - Shared/Public
        
        .target(
            name: "PADCore",
            path: "Sources/Shared/Public/PADCore"
        ),
        .target(
            name: "PADLogging",
            dependencies: ["FileHandlingModule"],
            path: "Sources/Shared/Public/PADLogging"
        ),
        
        // MARK: - Shared/Package
        
        .target(
            name: "FileHandlingModule",
            path: "Sources/Shared/Package/FileHandlingModule"
        ),
        .target(
            name: "ShellModule",
            path: "Sources/Shared/Package/ShellModule"
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
