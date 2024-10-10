//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import ProjectBuilderModule
@testable import CoreModule
import XCTest

class SwiftPackageFileAnalyzerTests: XCTestCase {
    
    func test_noPackageLibraryDifferences_causeNoChanges() throws {
        
        let handleFileExpectation = expectation(description: "handleFileExists is called twice")
        handleFileExpectation.expectedFulfillmentCount = 2
        
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { _ in
            handleFileExpectation.fulfill()
            return true
        }
        var shell = MockShell()
        shell.handleExecute = { _ in
            let packageDescription = SwiftPackageDescription(
                defaultLocalization: "en-en",
                name: "Name",
                toolsVersion: "1.0"
            )
            let encodedPackageDescription = try! JSONEncoder().encode(packageDescription)
            return String(data: encodedPackageDescription, encoding: .utf8)!
        }
        
        let projectAnalyzer = SwiftPackageFileAnalyzer(
            fileHandler: fileHandler,
            shell: shell,
            logger: nil
        )
        
        let changes = try projectAnalyzer.analyze(
            oldProjectUrl: URL(filePath: "NewPackage"),
            newProjectUrl: URL(filePath: "NewPackage")
        )
        
        let expectedChanges: [Change] = []
        XCTAssertEqual(changes.changes, expectedChanges)
        
        waitForExpectations(timeout: 1)
    }
    
    func test_packageLibraryDifferences_causeChanges() throws {
        
        let handleFileExpectation = expectation(description: "handleFileExists is called twice")
        handleFileExpectation.expectedFulfillmentCount = 2
        
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { _ in
            handleFileExpectation.fulfill()
            return true
        }
        
        var shell = MockShell()
        shell.handleExecute = { command in
            let packageDescription: SwiftPackageDescription
            
            if command.range(of: "NewPackage") != nil {
                packageDescription = SwiftPackageDescription(
                    defaultLocalization: "en-us",
                    name: "New Name",
                    platforms: [.init(name: "iOS", version: "15.0"), .init(name: "visionOS", version: "1.0")],
                    products: [
                        .init(name: "New Library", targets: ["New Target"]),
                        .init(name: "Some Library", targets: ["Some Target", "New Target"])
                    ],
                    targets: [
                        .init(name: "New Target", type: .binary, path: "new/path", moduleType: .swiftTarget),
                        .init(
                            name: "Some Target",
                            type: .library,
                            path: "some/new/path",
                            moduleType: .swiftTarget,
                            productDependencies: ["Some Product Dependency", "New Product Dependency"],
                            targetDependencies: ["Some Target Dependency", "New Target Dependency"]
                        ),
                    ],
                    toolsVersion: "1.0"
                )
            } else {
                packageDescription = SwiftPackageDescription(
                    defaultLocalization: "nl-nl",
                    name: "Old Name",
                    platforms: [.init(name: "iOS", version: "12.0"), .init(name: "macOS", version: "10.0")],
                    products: [
                        .init(name: "Old Library", targets: ["Old Target"]),
                        .init(name: "Some Library", targets: ["Some Target", "Old Target"])
                    ],
                    targets: [
                        .init(name: "Old Target", type: .test, path: "old/path", moduleType: .swiftTarget),
                        .init(
                            name: "Some Target",
                            type: .binary,
                            path: "some/old/path",
                            moduleType: .swiftTarget,
                            productDependencies: ["Some Product Dependency", "Old Product Dependency"],
                            targetDependencies: ["Some Target Dependency", "Old Target Dependency"]
                        ),
                    ],
                    toolsVersion: "2.0"
                )
            }
            
            let encodedPackageDescription = try! JSONEncoder().encode(packageDescription)
            return String(data: encodedPackageDescription, encoding: .utf8)!
        }
        
        let projectAnalyzer = SwiftPackageFileAnalyzer(
            fileHandler: fileHandler,
            shell: shell,
            logger: nil
        )
        
        let changes = try projectAnalyzer.analyze(
            oldProjectUrl: URL(filePath: "OldPackage"),
            newProjectUrl: URL(filePath: "NewPackage")
        )
        
        let expectedChanges: [Change] = [
            .init(
                changeType: .change(
                    oldDescription: "// swift-tools-version: 2.0",
                    newDescription: "// swift-tools-version: 1.0"
                ),
                parentPath: "Package.swift",
                listOfChanges: []
            ),
            .init(
                changeType: .change(
                    oldDescription: "defaultLocalization: \"nl-nl\"",
                    newDescription: "defaultLocalization: \"en-us\""
                ),
                parentPath: "Package.swift",
                listOfChanges: []
            ),
            .init(
                changeType: .change(
                    oldDescription: "name: \"Old Name\"",
                    newDescription: "name: \"New Name\""
                ),
                parentPath: "Package.swift",
                listOfChanges: []
            ),
            .init(
                changeType: .change(
                    oldDescription: "platforms: [iOS(12.0), macOS(10.0)]",
                    newDescription: "platforms: [iOS(15.0), visionOS(1.0)]"
                ),
                parentPath: "Package.swift",
                listOfChanges: [
                    "Added visionOS(1.0)",
                    "Changed from iOS(12.0) to iOS(15.0)",
                    "Removed macOS(10.0)"
                ]
            ),
            .init(
                changeType: .addition(
                    description: ".library(name: \"New Library\", targets: [\"New Target\"])"
                ),
                parentPath: "Package.swift / products",
                listOfChanges: []
            ),
            .init(
                changeType: .change(
                    oldDescription: ".library(name: \"Some Library\", targets: [\"Some Target\", \"Old Target\"])",
                    newDescription: ".library(name: \"Some Library\", targets: [\"Some Target\", \"New Target\"])"
                ),
                parentPath: "Package.swift / products",
                listOfChanges: [
                    "Added target \"New Target\"",
                    "Removed target \"Old Target\""
                ]
            ),
            .init(
                changeType: .removal(
                    description: ".library(name: \"Old Library\", targets: [\"Old Target\"])"
                ),
                parentPath: "Package.swift / products",
                listOfChanges: []
            ),
            .init(
                changeType: .addition(
                    description: ".binaryTarget(name: \"New Target\", path: \"new/path\")"
                ),
                parentPath: "Package.swift / targets",
                listOfChanges: []
            ),
            .init(
                changeType: .change(
                    oldDescription: ".binaryTarget(name: \"Some Target\", dependencies: [.target(name: \"Some Target Dependency\"), .target(name: \"Old Target Dependency\"), .product(name: \"Some Product Dependency\", ...), .product(name: \"Old Product Dependency\", ...)], path: \"some/old/path\")",
                    newDescription: ".target(name: \"Some Target\", dependencies: [.target(name: \"Some Target Dependency\"), .target(name: \"New Target Dependency\"), .product(name: \"Some Product Dependency\", ...), .product(name: \"New Product Dependency\", ...)], path: \"some/new/path\")"
                ),
                parentPath: "Package.swift / targets",
                listOfChanges: [
                    "Added dependency .target(name: \"New Target Dependency\")",
                    "Added dependency .product(name: \"New Product Dependency\", ...)",
                    "Changed path from \"some/old/path\" to \"some/new/path\"",
                    "Changed type from `.binaryTarget` to `.target`",
                    "Removed dependency .target(name: \"Old Target Dependency\")",
                    "Removed dependency .product(name: \"Old Product Dependency\", ...)"
                ]
            ),
            .init(
                changeType: .removal(
                    description: ".testTarget(name: \"Old Target\", path: \"old/path\")"
                ),
                parentPath: "Package.swift / targets",
                listOfChanges: []
            )
        ]
        
        XCTAssertEqual(changes.changes, expectedChanges)
        
        waitForExpectations(timeout: 1)
    }
    
    func test_project_causesNoChanges() throws {
        
        let handleFileExpectation = expectation(description: "handleFileExists is called once")
        
        var fileHandler = MockFileHandler()
        fileHandler.handleFileExists = { _ in
            handleFileExpectation.fulfill()
            return false // Package.swift file does not exist
        }
        let projectAnalyzer = SwiftPackageFileAnalyzer(
            fileHandler: fileHandler,
            logger: nil
        )
        
        let changes = try projectAnalyzer.analyze(
            oldProjectUrl: URL(filePath: "OldProject"),
            newProjectUrl: URL(filePath: "NewProject")
        )
        
        let expectedChanges: [Change] = []
        XCTAssertEqual(changes.changes, expectedChanges)
        
        waitForExpectations(timeout: 1)
    }
}
