// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "public-api-diff",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // swift-package-manager depends on an old swift-argument-parser so we have to use the same
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.2.3"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.4"),
        .package(url: "https://github.com/swiftlang/swift-package-manager", revision: "swift-5.10.1-RELEASE"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "public-api-diff",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PackageDescription", package: "swift-package-manager")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "UnitTests",
            dependencies: ["public-api-diff"],
            resources: [
                // Copy Tests/ExampleTests/Resources directories as-is.
                // Use to retain directory structure.
                // Will be at top level in bundle.
                .copy("Resources/dummy.abi.json"),
                .copy("Resources/dummi-abi-flat-definition.md")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["public-api-diff"],
            resources: [
                // Copy Tests/ExampleTests/Resources directories as-is.
                // Use to retain directory structure.
                // Will be at top level in bundle.
                .copy("Resources/expected-reference-changes.md")
            ]
        )
    ]
)
