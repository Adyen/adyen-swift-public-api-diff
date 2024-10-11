# ``PADOutputGenerator``

Allows generation of human readable output from the provided information

## Usage

```swift
// Generated in previous steps
let warnings: [String] = ...
let changes: [String: [PADChange]] = ...
let oldVersionName: String = ...
let newVersionName: String = ...
let allTargets: [String] = ...
let swiftInterfaceFiles: [PADSwiftInterfaceFile] = ...

let outputGenerator: any PADOutputGenerating = PADMarkdownOutputGenerator()

let markdownOutput: String = try outputGenerator.generate(
    from: changes,
    allTargets: allTargets,
    oldVersionName: oldVersionName,
    newVersionName: newVersionName,
    warnings: warnings
)
```
