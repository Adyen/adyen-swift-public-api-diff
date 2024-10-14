# ``PADOutputGenerator``

Allows generation of human readable output from the provided information

## Usage

```swift
// Generated in previous steps
let warnings: [String] = ...
let changes: [String: [Change]] = ...
let oldVersionName: String = ...
let newVersionName: String = ...
let allTargets: [String] = ...
let swiftInterfaceFiles: [SwiftInterfaceFile] = ...

let outputGenerator: any OutputGenerating = MarkdownOutputGenerator()

let markdownOutput: String = try outputGenerator.generate(
    from: changes,
    allTargets: allTargets,
    oldVersionName: oldVersionName,
    newVersionName: newVersionName,
    warnings: warnings
)
```
