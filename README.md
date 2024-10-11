[![🧪 Run Tests](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml)

# Swift Public API diff

This tool allows comparing 2 versions of a swift (sdk) project and lists all changes in a human readable way.

It makes use of `.swiftinterface` files that get produced during the archiving of a swift project and parses them using [`swift-syntax`](https://github.com/swiftlang/swift-syntax).

## PADProjectBuilder

Allows building the old & new project and outputs a list of `.swiftinterface` file references as well as changes that happened between project files.

### ProjectSetupHelper

Helps setting up the projects from a `ProjectSource` which includes cloning the repository if needed.

### SwiftPackageFileAnalyzer

If the project type is of type `swift package` the Package.swift gets analyzed for added/removed/changed products/targets/dependencies and any issues/warnings

### SwiftInterfaceProducer

Archives the project and locates the `.swiftinterface` files for the available targets.
If the project is of type `swift package` the `Package.swift` gets altered by adding a new product that contains all targets.

## PADSwiftInterfaceDiff

Takes a list of `.swiftinterface` references and detects changes between the old and new version.

![image](https://github.com/user-attachments/assets/f836c963-6c16-4694-a481-9f0e598fbcd5)

### SwiftInterfaceParser

Parses the source content of a swift file into intermediate objects for further processing

### SwiftInterfaceAnalyzer

Analyzes 2 root `SwiftInterfaceElement`s and detects `addition`s & `removal`s.

### SwiftInterfaceChangeConsolidator

The `ChangeConsolidator` takes 2 independent changes (`addition` & `removal`) and tries to match them into a list of `Change`s based on the consoldiatableName, type and parent.

| Match |
| --- |
| ![image](https://github.com/user-attachments/assets/f057c160-f85d-45af-b08f-203b89e43b41) |

| No Match | Potentially false positive |
| --- | --- |
| ![image](https://github.com/user-attachments/assets/5ae3b624-b32a-41cc-9026-8ba0117cec57) | ![image](https://github.com/user-attachments/assets/a7e60605-fc1c-49ef-a203-d6a5466a6fda) |

## PADOutputGenerator

Receives a dictionary of `[{SCOPE_NAME}: [PADChange]]` and processes them into a human readable format.

# Alternatives
- `xcrun swift-api-digester -dump-sdk` & `xcrun swift-api-digester -diagnose-sdk`

# Inspiration
- https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
  - For parsing swift files using [swift-syntax](https://github.com/swiftlang/swift-syntax)'s [`SyntaxVisitor`](https://github.com/swiftlang/swift-syntax/blob/main/Sources/SwiftSyntax/generated/SyntaxVisitor.swift)
