# ``PADOutputGenerator``

Allows generation of human readable output from the provided information

## Usage

```swift
// Generated in previous steps
let changes: [String: [Change]] = ...
let allTargets: [String] = ...
let oldVersionName: String = ...
let newVersionName: String = ...
let warnings: [String] = ...

let outputGenerator: any OutputGenerating = MarkdownOutputGenerator()

let markdownOutput: String = try outputGenerator.generate(
    from: changes,
    allTargets: allTargets,
    oldVersionName: oldVersionName,
    newVersionName: newVersionName,
    warnings: warnings
)
```

### JSON output

``PADOutputGenerator/JSONOutputGenerator`` produces a deterministic, versioned JSON document that other tools can process.
The model (``PADOutputGenerator/JSONReport``) is `Codable`, so it can be decoded again.
Consumers should check `formatVersion` (see ``PADOutputGenerator/JSONReport/currentFormatVersion``) - not the tool version.

```swift
let outputGenerator = JSONOutputGenerator(toolVersion: "1.0.0")
let json: String = try outputGenerator.generate(
    from: changes,
    allTargets: allTargets,
    oldVersionName: oldVersionName,
    newVersionName: newVersionName,
    platform: nil,
    warnings: warnings
)
```

---

Example output for ``PADOutputGenerator/MarkdownOutputGenerator``

## 👀 3 public changes detected
_Comparing `old` to `new`_

---
## SomeModule
#### ❇️ Added
```swift
public protocol NewProtocol {
    var property: String { get }
}
```
#### 🔀 Changed
```swift
// From
open class SomeClass : SomeProtocol, OldProtocol

// To
open class SomeClass : SomeProtocol, NewProtocol

/**
Changes:
- Added `NewProtocol` conformance
- Removed `OldProtocol` conformance
*/
```
#### 😶‍🌫️ Removed
```swift
public protocol OldProtocol
```
