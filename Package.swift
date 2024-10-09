// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "public-api-diff",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.54.6")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "public-api-diff",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources"
        ),
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
