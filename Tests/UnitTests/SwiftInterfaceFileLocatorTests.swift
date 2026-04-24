//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import FileHandlingModule
@testable import PADSwiftInterfaceFileLocator
import XCTest

class SwiftInterfaceFileLocatorTests: XCTestCase {

    func test_locate_public_swiftinterface() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"
        let findResult = "./Build/Products/MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { command in
            XCTAssertEqual(command, "cd '\(derivedDataPath)'; find . -type d -name '\(scheme).swiftmodule'")
            return findResult
        }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { path in
            XCTAssertEqual(path, "/path/to/derived/data/./Build/Products/MyModule.swiftmodule")
            return [
                "arm64-apple-ios.swiftinterface",
                "arm64-apple-ios.private.swiftinterface",
                "x86_64-apple-ios-simulator.swiftinterface"
            ]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        
        XCTAssertEqual(
            result.path(),
            "/path/to/derived/data/./Build/Products/MyModule.swiftmodule/arm64-apple-ios.swiftinterface"
        )
    }

    func test_locate_private_swiftinterface() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"
        let findResult = "./Build/Products/MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { _ in
            [
                "arm64-apple-ios.swiftinterface",
                "arm64-apple-ios.private.swiftinterface",
                "x86_64-apple-ios-simulator.private.swiftinterface"
            ]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .private)
        
        XCTAssertEqual(
            result.path(),
            "/path/to/derived/data/./Build/Products/MyModule.swiftmodule/arm64-apple-ios.private.swiftinterface"
        )
    }

    func test_locate_package_swiftinterface() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"
        let findResult = "./Build/Products/MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { _ in
            [
                "arm64-apple-ios.swiftinterface",
                "arm64-apple-ios.package.swiftinterface",
                "x86_64-apple-ios-simulator.package.swiftinterface"
            ]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .package)
        
        XCTAssertEqual(
            result.path(),
            "/path/to/derived/data/./Build/Products/MyModule.swiftmodule/arm64-apple-ios.package.swiftinterface"
        )
    }

    func test_locate_withTrailingSlashInDerivedDataPath() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data/"
        let findResult = "./Build/Products/MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { path in
            XCTAssertFalse(path.contains("//"), "Path should not contain double slashes: \(path)")
            return ["arm64-apple-ios.swiftinterface"]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        
        let resultPath = result.path()
        XCTAssertFalse(resultPath.contains("//"), "Result path should not contain double slashes: \(resultPath)")
    }

    func test_locate_pathConstructionWithoutTrailingSlash() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/Users/test/DerivedData"
        let findResult = "./MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { path in
            XCTAssertEqual(path, "/Users/test/DerivedData/./MyModule.swiftmodule")
            return ["arm64-apple-ios.swiftinterface"]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        
        XCTAssertEqual(
            result.path(),
            "/Users/test/DerivedData/./MyModule.swiftmodule/arm64-apple-ios.swiftinterface"
        )
    }

    func test_locate_public_excludesPrivateAndPackage() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"
        let findResult = "./MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { _ in
            [
                "arm64-apple-ios.private.swiftinterface",
                "arm64-apple-ios.package.swiftinterface",
                "arm64-apple-ios.swiftinterface"
            ]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        
        XCTAssertTrue(result.path().hasSuffix("arm64-apple-ios.swiftinterface"))
        XCTAssertFalse(result.path().hasSuffix(".private.swiftinterface"))
        XCTAssertFalse(result.path().hasSuffix(".package.swiftinterface"))
    }

    func test_locate_throwsWhenSwiftModuleNotFound() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in "" }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { _ in
            throw FileHandlerError.pathDoesNotExist(path: "")
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        XCTAssertThrowsError(try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public))
    }

    func test_locate_throwsWhenSwiftInterfaceNotFound() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"
        let findResult = "./MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { _ in
            []
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        XCTAssertThrowsError(try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public))
    }
}
