[![🧪 Run Tests](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAdyen%2Fadyen-swift-public-api-diff%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Adyen/adyen-swift-public-api-diff)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAdyen%2Fadyen-swift-public-api-diff%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Adyen/adyen-swift-public-api-diff)
[![Mint](https://img.shields.io/badge/Mint-adyen%E2%80%93swift%E2%80%93public%E2%80%93api%E2%80%93diff-40c8a7?logo=leaf&logoColor=white)](#installation)

![github-header](https://github.com/user-attachments/assets/08ec7d60-eb0f-4937-b44a-afff02eff72c)


# Swift Public API diff

Compare two versions of a Swift SDK or project and generate a human-readable report of API changes.

The tool parses `.swiftinterface` files using [`SwiftSyntax`](https://github.com/swiftlang/swift-syntax). It can build projects for you, compare existing interface files, or locate interfaces inside built frameworks.

[Quick start](#quick-start) · [Installation](#installation) · [Usage](#usage) · [Output](#output-format) · [GitHub Action](#github-action)

## Requirements
- **Xcode** >= 26.6, including the command line tools
- **Swift** >= 6.3
- **macOS** >= 13.0 for the tool and library products; your Xcode installation may require a newer macOS version

<details>
<summary>Check or select your Swift toolchain</summary>

The pinned `swift-testing` dependency requires Swift 6.3, even though this package's manifest declares Swift tools version 5.9. Check the selected toolchain before building:

```bash
xcodebuild -version
xcrun swift --version
```

If multiple Xcode versions are installed, select a compatible one using `DEVELOPER_DIR` or `xcode-select`.

</details>

## Quick start

With two existing `.swiftinterface` files, build the tool from source and save a Markdown report. Replace `old.swiftinterface` and `new.swiftinterface` with your file paths:

```bash
git clone https://github.com/Adyen/adyen-swift-public-api-diff.git
cd adyen-swift-public-api-diff
swift run public-api-diff swift-interface \
    --old old.swiftinterface \
    --new new.swiftinterface \
    --target-name MyModule \
    --api-scope public \
    --output api-comparison.md
```

For [JSON output](#json-output), add `--format json` and change the output path to `api-comparison.json`.

Need to build the compared projects first? Use the [`project` command](#from-project-to-output) instead.

## Installation

<details>
<summary>Use as a Swift Package Manager dependency</summary>

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Adyen/adyen-swift-public-api-diff", from: "0.13.0")
]
```

Available library products:
- **SwiftInterfaceDiff** - Core diffing functionality for `.swiftinterface` files
- **PublicApiDiff** - Full API including project building, package analysis, and output generation

</details>

<details>
<summary>Install the CLI with Mint</summary>

With [Mint](https://github.com/yonaskolb/mint) installed:

```bash
mint install Adyen/adyen-swift-public-api-diff
```

</details>

<details>
<summary>Build the CLI from source</summary>

```bash
git clone https://github.com/Adyen/adyen-swift-public-api-diff.git
cd adyen-swift-public-api-diff
swift build --configuration release
```

The binary will be available at `.build/release/public-api-diff`.

</details>

## Usage

Choose the command that matches your inputs:

| Command | Inputs | Builds the project? |
|---------|--------|---------------------|
| [`project`](#from-project-to-output) | Local project directories or Git references | Yes |
| [`swift-interface`](#from-swiftinterface-to-output) | Two `.swiftinterface` files | No |
| [`framework`](#from-framework-to-output) | Two built `.framework` directories containing interfaces | No |

This README describes the current branch. For a released version, use the README at the corresponding Git tag.
 
### From Project to Output

<details>
<summary>Build and compare Swift packages or Xcode projects</summary>

`--old` and `--new` accept an existing local directory or a Git source in the form `branch-or-tag~repository-url`. A bare branch name is not a project source.

Swift packages are built by default. Add `--scheme "YourScheme"` when comparing Xcode projects.

- Build using the iOS SDK (requires an iOS Simulator SDK to be installed)
```bash
swift run public-api-diff \
    project \
    --platform iOS \
    --new "develop~https://github.com/Adyen/adyen-ios.git" \
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git"
```
- Build using the macOS SDK
```bash
swift run public-api-diff \
    project \
    --platform macOS \
    --new "main~https://github.com/Adyen/adyen-swift-public-api-diff" \
    --old "0.4.0~https://github.com/Adyen/adyen-swift-public-api-diff"
```

For all available options and their defaults:

```bash
swift run public-api-diff project --help
```

</details>
 
### From `.swiftinterface` to Output

<details>
<summary>Generate and compare interface files</summary>

**1.** Build 2 versions of your project with `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`
```bash
xcodebuild clean build \
    -scheme "YOUR_SCHEME" \
    -derivedDataPath .build \
    -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
    -destination "generic/platform=iOS Simulator" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
```

**2.** Provide the `.swiftinterface` files to the public api diff
```bash
swift run public-api-diff \
    swift-interface \
    --new "new/path/to/project.swiftinterface" \
    --old "old/path/to/project.swiftinterface"
```
 
For all available options and their defaults:

```bash
swift run public-api-diff swift-interface --help
```

</details>

### From `.framework` to Output

<details>
<summary>Compare interfaces inside built frameworks</summary>

```bash
swift run public-api-diff \
    framework \
    --target-name "TargetName" \
    --new "new/path/to/project.framework" \
    --old "old/path/to/project.framework"
```

For all available options and their defaults:

```bash
swift run public-api-diff framework --help
```

</details>

## API Scope

The default scope is `all`. Choose `public` or `package` to filter explicitly non-public declarations.

<details>
<summary>Scope values, interface types, and filtering limitations</summary>

Interfaces that were generated without library evolution (e.g. `BUILD_LIBRARY_FOR_DISTRIBUTION = NO`) still contain `private`, `fileprivate` and `internal` declarations.
Use `--api-scope` on any of the three commands to define which declarations are considered part of the API:

| Value | Keeps | Drops |
|-------|-------|-------|
| `all` (default) | everything | nothing |
| `package` | `public`, `open`, `package` | `internal`, `fileprivate`, `private` |
| `public` | `public`, `open` | `package`, `internal`, `fileprivate`, `private` |

`--api-scope` decides which *declarations* to keep. `--swift-interface-type` decides which *file* to read.
The `public` interface file is the default for `project` and `framework`; choosing it does not enable `--api-scope public`.

### Filtering limitations

- Only an **explicit** access modifier hides a declaration. Declarations without one (enum cases, protocol requirements, members of an extension without access modifier) are kept.
- `public private(set) var` is kept, only the setter is restricted.
- `@usableFromInline` declarations are kept, as they are part of the ABI.
- Members of a removed type are removed with it.
- An extension whose members are all removed is removed as well, unless it adds a conformance (`extension T: P`). The conformance is part of the API.
- Declarations in `#if` blocks are filtered like any other declaration.
- Declarations are **not** removed because they are only *reachable* through hidden ones. A `public func make() -> HiddenType` stays in the report.
- A `public` type whose members are all removed stays in the report, as the type itself is still API.
- Filtering is syntactic. Access control inherited from an enclosing extension modifier (e.g. `internal extension T { func f() }`) is handled by removing the whole extension, but access levels that are only implied by the context are not inferred.

</details>

## Release Build

<details>
<summary>Build and run the optimized CLI</summary>

### Create
```bash
swift build --configuration release
```

### Run
```bash
.build/release/public-api-diff \
    project \
    --platform iOS \
    --new "develop~https://github.com/Adyen/adyen-ios.git" \
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git"
```
```bash
.build/release/public-api-diff \
    swift-interface \
    --new "new/path/to/project.swiftinterface" \
    --old "old/path/to/project.swiftinterface"
```
```bash
.build/release/public-api-diff \
    framework \
    --target-name "TargetName" \
    --new "new/path/to/project.framework" \
    --old "old/path/to/project.framework"
```

</details>

## Output Format

The tool generates a Markdown report of API changes, organized by module/target. Use [`--api-scope`](#api-scope) to control which declarations are included.

<details>
<summary>Example Markdown report</summary>

````markdown
# 👀 3 public changes detected
_Comparing `develop` to `5.12.0`_

---
## `ModuleName`
#### ❇️ Added
```swift
public func newFunction()
```
#### 🔀 Changed
```swift
// From
public func existingFunction(param: String)

// To
public func existingFunction(param: String, newParam: Int)
```
#### 😶‍🌫️ Removed
```swift
public func deprecatedFunction()
```
````

</details>

The output can be written to a file using the `--output` flag or printed to stdout.

### JSON output
Use `--format json` on `project`, `swift-interface`, or `framework` for a machine-readable report. The default is `markdown`.

<details>
<summary>JSON examples, schema, and versioning</summary>

```bash
swift run public-api-diff swift-interface \
    --old old.swiftinterface \
    --new new.swiftinterface \
    --target-name MyModule \
    --format json

swift run public-api-diff project \
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git" \
    --new "develop~https://github.com/Adyen/adyen-ios.git" \
    --platform iOS \
    --format json \
    --output report.json
```

- Without `--output`, stdout contains only the JSON document, so it can be piped (`… --format json | jq`). With `--output`, the report is written to that file instead.
- In JSON mode the tool exits with a non-zero status on errors (and writes no output). The `markdown` mode keeps exiting with `0`.
- Within the same tool version, the same inputs produce byte-identical output.
- The structure is described by the [JSON Schema](docs/public-api-diff.schema.v1.json).

**Versioning:** The document contains a `formatVersion` (currently `1`). It only changes for breaking changes (a field is removed, renamed or changes its meaning, or a new value is added to an enumeration like `kind`).
New optional fields can be added without changing it, so consumers must ignore unknown fields. `tool.version` is informational (the version of `public-api-diff`) - rely on `formatVersion` for compatibility checks.

```json
{
  "formatVersion": 1,
  "tool": { "name": "public-api-diff", "version": "0.12.0" },
  "oldVersionName": "v1.0",
  "newVersionName": "v2.0",
  "platform": null,
  "analyzedTargets": ["MyModule"],
  "warnings": [],
  "summary": { "added": 1, "modified": 0, "removed": 0, "total": 1 },
  "targets": {
    "MyModule": [
      {
        "kind": "added",
        "parentPath": "MyType",
        "before": null,
        "after": "public func reload(animated: Swift.Bool) -> Swift.Void",
        "details": [],
        "conditions": []
      }
    ]
  }
}
```

</details>

## GitHub Action
The GitHub Action adds the report to the step summary and posts a comment on same-repository pull requests. Pull requests from forks receive the step summary only.

<details>
<summary>Action configuration example</summary>

```yaml
- name: 🔍 Detect Changes
  uses: Adyen/adyen-swift-public-api-diff@0.13.0
  with:
    platform: "iOS"
    new: "develop~https://github.com/Adyen/adyen-ios.git"
    old: "5.12.0~https://github.com/Adyen/adyen-ios.git"
```

</details>

See the [example workflow](Examples/github-workflow.yml) for checkout and Xcode setup.

## More Resources

<details>
<summary>Related tools, projects, and inspiration</summary>

### Alternatives
- **swift-api-digester**
  - `xcrun swift-api-digester -dump-sdk`
  - `xcrun swift-api-digester -diagnose-sdk`

### Projects using `public-api-diff`
- [Adyen iOS Checkout](https://github.com/Adyen/adyen-ios)

### Inspiration
- [Hatch's symbol parser](https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift), which uses SwiftSyntax's [`SyntaxVisitor`](https://github.com/swiftlang/swift-syntax/blob/main/Sources/SwiftSyntax/generated/SyntaxVisitor.swift) to parse Swift files.

</details>

## Contributing and Support

Contributions are welcome. See our [contribution guidelines](https://github.com/Adyen/.github/blob/master/CONTRIBUTING.md), or [open an issue](https://github.com/Adyen/adyen-swift-public-api-diff/issues) for bugs and feature requests.

## License    
MIT license. See [LICENSE.txt](LICENSE.txt).
