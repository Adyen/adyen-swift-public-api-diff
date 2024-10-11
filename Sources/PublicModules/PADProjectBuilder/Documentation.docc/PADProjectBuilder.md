# ``PADProjectBuilder``

The ``PADProjectBuilder/PADProjectBuilder`` builds the old & new version of a project and outputs a list of ``PADCore/PADSwiftInterfaceFile``s as well as changes that happened to the project files including any warnings if applicable.

## Usage

```swift
let oldSource: PADProjectSource = try .from("develop~https://github.com/some/repository")
let newSource: PADProjectSource = try .from("some/local/path")

let projectBuilder = PADProjectBuilder(
    projectType: .swiftPackage,
    swiftInterfaceType: .public
)

let projectBuilderResult: PADProjectBuilder.Result = try await projectBuilder.build(
    oldSource: oldSource,
    newSource: newSource
)
```
