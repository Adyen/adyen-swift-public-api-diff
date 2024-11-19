# ``PADProjectBuilder``

The ``PADProjectBuilder/ProjectBuilder`` builds the old & new version of a project and outputs a list of ``PADCore/SwiftInterfaceFile``s as well as changes that happened to the project files including any warnings if applicable.

## Usage

```swift
let oldSource: ProjectSource = try .from("develop~https://github.com/Adyen/adyen-ios.git")
let newSource: ProjectSource = try .from("some/local/path")

let projectBuilder = ProjectBuilder(
    projectType: .swiftPackage, // .xcodeProject("scheme_name")
    platform: .iOS, // .macOS
    swiftInterfaceType: .public // .private / .package
)

let projectBuilderResult: ProjectBuilder.Result = try await projectBuilder.build(
    oldSource: oldSource,
    newSource: newSource
)
```
