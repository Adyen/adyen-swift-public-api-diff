# ``PADPackageFileAnalyzer``

The ``PADPackageFileAnalyzer/SwiftPackageFileAnalyzer`` allows analyzing of 2 versions of a `Package.swift` file.

It lists all changes to products, dependencies and targets + surfaces any warnings that the new version of the `Package.swift` file might have.
Under the hood it uses `swift package describe --type json` to get a description of the `Package.swift` file

## Usage

```swift
let swiftPackageFileAnalyzer = SwiftPackageFileAnalyzer()

let swiftPackageAnalysis = try swiftPackageFileAnalyzer.analyze(
    oldProjectUrl: projectDirectories.old,
    newProjectUrl: projectDirectories.new
)

let warnings: [String] = swiftPackageAnalysis.warnings
let changes: [Change] = swiftPackageAnalysis.changes
```
