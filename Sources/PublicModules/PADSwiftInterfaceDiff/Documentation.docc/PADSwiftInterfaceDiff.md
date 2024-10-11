# ``PADSwiftInterfaceDiff``

The ``PADSwiftInterfaceDiff`` consumes a list of ``PADCore/PADSwiftInterfaceFile``s and detects changes between the old and new version

## Usage

```swift
let swiftInterfaceFiles: [PADSwiftInterfaceFile] = ...

let swiftInterfaceDiff = PADSwiftInterfaceDiff()

let changes: [String: [PADChange]] = try await swiftInterfaceDiff.run(
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
