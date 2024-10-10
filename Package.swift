// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private extension String {
    static var core: Self { "CoreModule" }
    static var fileHandling: Self { "FileHandlingModule" }
    static var shell: Self { "ShellModule" }
    static var git: Self { "GitModule" }
    static var logging: Self { "LoggingModule" }
    static var outputGenerator: Self { "OutputGeneratorModule" }
    static var swiftInterfaceAnalyzerModule: Self { "SwiftInterfaceAnalyzerModule" }
    static var projectSetupModule: Self { "ProjectSetupModule" }
    static var swiftInterfaceProducerModule: Self { "SwiftInterfaceProducerModule" }
    static var swiftPackageFileHelperModule: Self { "SwiftPackageFileHelperModule" }
    static var swiftPackageFileAnalyzerModule: Self { "SwiftPackageFileAnalyzerModule" }
    
}

extension Target.Dependency {
    static var core: Self { .byName(name: .core) }
    static var fileHandling: Self { .byName(name: .fileHandling) }
    static var shell: Self { .byName(name: .shell) }
    static var git: Self { .byName(name: .git) }
    static var logging: Self { .byName(name: .logging) }
    static var outputGenerator: Self { .byName(name: .outputGenerator) }
    static var swiftInterfaceAnalyzerModule: Self { .byName(name: .swiftInterfaceAnalyzerModule) }
    static var projectSetupModule: Self { .byName(name: .projectSetupModule) }
    static var swiftInterfaceProducerModule: Self { .byName(name: .swiftInterfaceProducerModule) }
    static var swiftPackageFileHelperModule: Self { .byName(name: .swiftPackageFileHelperModule) }
    static var swiftPackageFileAnalyzerModule: Self { .byName(name: .swiftPackageFileAnalyzerModule) }
}

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
            targets: [.swiftInterfaceAnalyzerModule]
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
                .core,
                .logging,
                .shell,
                .git,
                .outputGenerator,
                .fileHandling,
                .projectSetupModule,
                .swiftInterfaceProducerModule,
                .swiftInterfaceAnalyzerModule,
                .swiftPackageFileHelperModule,
                .swiftPackageFileAnalyzerModule,
                "ProjectBuilderModule",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/CommandLineTool"
        ),
        
        // MARK: - Modules
        
        .target(name: .core),
        .target(name: .shell, dependencies: [
            .core
        ]),
        .target(name: .logging, dependencies: [
            .core,
            .fileHandling
        ]),
        .target(name: .git, dependencies: [
            .core,
            .shell,
            .fileHandling,
            .logging
        ]),
        .target(name: .outputGenerator, dependencies: [
            .core
        ]),
        .target(name: .fileHandling, dependencies: [
            .core
        ]),
        .target(name: .swiftInterfaceAnalyzerModule, dependencies: [
            .core,
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax"),
        ]),
        .target(name: .swiftInterfaceProducerModule, dependencies: [
            .core,
            .fileHandling,
            .logging,
            .swiftPackageFileHelperModule
        ]),
        .target(name: .projectSetupModule, dependencies: [
            .shell,
            .fileHandling,
            .logging,
            .git
        ]),
        .target(name: .swiftPackageFileHelperModule, dependencies: [
            .core,
            .fileHandling,
            .logging
        ]),
        .target(name: .swiftPackageFileAnalyzerModule, dependencies: [
            .core,
            .fileHandling,
            .shell,
            .logging,
            .swiftPackageFileHelperModule
        ]),
        .target(name: "ProjectBuilderModule", dependencies: [
            .swiftPackageFileAnalyzerModule,
            .swiftPackageFileHelperModule,
            .fileHandling,
            .logging
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
