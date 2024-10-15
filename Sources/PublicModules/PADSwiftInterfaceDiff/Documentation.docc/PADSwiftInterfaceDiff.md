# ``PADSwiftInterfaceDiff``

The ``SwiftInterfaceDiff`` consumes a list of ``PADCore/SwiftInterfaceFile``s and detects changes between the old and new version

## Usage

```swift
let swiftInterfaceFiles: [SwiftInterfaceFile] = ...

let swiftInterfaceDiff = SwiftInterfaceDiff()

let changes: [String: [Change]] = try await swiftInterfaceDiff.run(
    with: swiftInterfaceFiles
)
```

## How it works
![SwiftInterfaceDiff](SwiftInterfaceDiff.png)

## Consolidating individual Changes
### Match
![False positive](ChangeConsolidator_Match.png)
### No Match
![False positive](ChangeConsolidator_NoMatch.png)
### False positive
![False positive](ChangeConsolidator_FalsePositive.png)
