//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import FileHandlingModule
@testable import PADSwiftInterfaceFileLocator
import Testing

@Suite
struct SwiftInterfaceFileLocatorTests {

    @Test func locatePublicSwiftinterface() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data"
        let findResult = "./Build/Products/MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { command in
            #expect(command == "cd '\(derivedDataPath)'; find . -type d -name '\(scheme).swiftmodule'")
            return findResult
        }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { path in
            #expect(path == "/path/to/derived/data/./Build/Products/MyModule.swiftmodule")
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
        
        #expect(
            result.path() ==
            "/path/to/derived/data/./Build/Products/MyModule.swiftmodule/arm64-apple-ios.swiftinterface"
        )
    }

    @Test func locatePrivateSwiftinterface() throws {
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
        
        #expect(
            result.path() ==
            "/path/to/derived/data/./Build/Products/MyModule.swiftmodule/arm64-apple-ios.private.swiftinterface"
        )
    }

    @Test func locatePackageSwiftinterface() throws {
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
        
        #expect(
            result.path() ==
            "/path/to/derived/data/./Build/Products/MyModule.swiftmodule/arm64-apple-ios.package.swiftinterface"
        )
    }

    @Test func locateWithTrailingSlashInDerivedDataPath() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/path/to/derived/data/"
        let findResult = "./Build/Products/MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { path in
            #expect(!path.contains("//"), "Path should not contain double slashes: \(path)")
            return ["arm64-apple-ios.swiftinterface"]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        
        let resultPath = result.path()
        #expect(!resultPath.contains("//"), "Result path should not contain double slashes: \(resultPath)")
    }

    @Test func locatePathConstructionWithoutTrailingSlash() throws {
        let scheme = "MyModule"
        let derivedDataPath = "/Users/test/DerivedData"
        let findResult = "./MyModule.swiftmodule"

        var mockShell = MockShell()
        mockShell.handleExecute = { _ in findResult }

        var mockFileHandler = MockFileHandler()
        mockFileHandler.handleContentsOfDirectory = { path in
            #expect(path == "/Users/test/DerivedData/./MyModule.swiftmodule")
            return ["arm64-apple-ios.swiftinterface"]
        }

        let locator = SwiftInterfaceFileLocator(
            fileHandler: mockFileHandler,
            shell: mockShell,
            logger: nil
        )

        let result = try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        
        #expect(
            result.path() ==
            "/Users/test/DerivedData/./MyModule.swiftmodule/arm64-apple-ios.swiftinterface"
        )
    }

    @Test func locatePublicExcludesPrivateAndPackage() throws {
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
        
        #expect(result.path().hasSuffix("arm64-apple-ios.swiftinterface"))
        #expect(!result.path().hasSuffix(".private.swiftinterface"))
        #expect(!result.path().hasSuffix(".package.swiftinterface"))
    }

    @Test func locateThrowsWhenSwiftModuleNotFound() throws {
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

        #expect(throws: (any Error).self) {
            try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        }
    }

    @Test func locateThrowsWhenSwiftInterfaceNotFound() throws {
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

        #expect(throws: (any Error).self) {
            try locator.locate(for: scheme, derivedDataPath: derivedDataPath, type: .public)
        }
    }
}
