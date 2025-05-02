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
