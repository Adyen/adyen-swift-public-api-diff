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
            targets: ["SwiftInterfaceAnalyzerModule"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.6")
    ],
    targets: [
        .executableTarget(
            name: "public-api-diff",
            dependencies: [
                "CoreModule",
                "LoggingModule",
                "OutputGeneratorModule",
                "FileHandlingModule",
                "ProjectBuilderModule",
                "SwiftInterfaceAnalyzerModule",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/CommandLineTool"
        ),
        
        // MARK: - Modules
        
        .target(name: "CoreModule"),
        .target(name: "FileHandlingModule", dependencies: []),
        .target(name: "ShellModule"),
        .target(name: "LoggingModule", dependencies: [
            "FileHandlingModule"
        ]),
        .target(name: "OutputGeneratorModule", dependencies: [
            "CoreModule"
        ]),
        .target(name: "SwiftInterfaceAnalyzerModule", dependencies: [
            "CoreModule",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax"),
        ]),
        .target(name: "ProjectBuilderModule", dependencies: [
            "CoreModule",
            "FileHandlingModule",
            "LoggingModule",
            "ShellModule",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax"),
        ]),
        
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
