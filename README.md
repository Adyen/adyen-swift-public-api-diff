[![🧪 Run Tests](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAdyen%2Fadyen-swift-public-api-diff%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Adyen/adyen-swift-public-api-diff)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAdyen%2Fadyen-swift-public-api-diff%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Adyen/adyen-swift-public-api-diff)
[![Mint](https://img.shields.io/badge/Mint-adyen%E2%80%93swift%E2%80%93public%E2%80%93api%E2%80%93diff-40c8a7?logo=leaf&logoColor=white)](#install-via-mint)

![github-header](https://github.com/user-attachments/assets/08ec7d60-eb0f-4937-b44a-afff02eff72c)


# Swift Public API diff

This tool allows comparing 2 versions of a swift (sdk) project and lists all changes in a human readable way.

It makes use of `.swiftinterface` files that get produced during the archiving of a swift project and parses them using [`swift-syntax`](https://github.com/swiftlang/swift-syntax).  

## Contributing
We strongly encourage you to contribute to our repository. Find out more in our [contribution guidelines](https://github.com/Adyen/.github/blob/master/CONTRIBUTING.md)

## Requirements
- **Xcode** >= 26.6 (incl. Xcode command line tools)
- **Swift** >= 6.2
- **macOS** >= 13.0

## Installation

### Swift Package Manager (as a dependency)

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Adyen/adyen-swift-public-api-diff", from: "0.12.0")
]
```

Available library products:
- **SwiftInterfaceDiff** - Core diffing functionality for `.swiftinterface` files
- **PublicApiDiff** - Full API including project building, package analysis, and output generation

### Install via [Mint](https://github.com/yonaskolb/mint)
```
mint install Adyen/adyen-swift-public-api-diff
```

### Build from Source

```bash
git clone https://github.com/Adyen/adyen-swift-public-api-diff.git
cd adyen-swift-public-api-diff
swift build --configuration release
```

The binary will be available at `.build/release/public-api-diff`.

## Usage
 
### From Project to Output

- Build using the iOS sdk (Requires an iOS Simulator to be installed)
```bash
swift run public-api-diff \
    project \
    --platform iOS \
    --new "develop~https://github.com/Adyen/adyen-ios.git" \
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git"
```
- Build using the macOS sdk
```bash
swift run public-api-diff \
    project \
    --platform macOS \
    --new "main~https://github.com/Adyen/adyen-swift-public-api-diff" \
    --old "0.4.0~https://github.com/Adyen/adyen-swift-public-api-diff"
```

<details><summary><b>--help:</b></summary>

```
USAGE: public-api-diff project --new <new> --old <old> --platform <platform> [--scheme <scheme>] [--swift-interface-type <swift-interface-type>] [--output <output>] [--log-output <log-output>] [--log-level <log-level>]

OPTIONS:
  --new <new>             Specify the updated version to compare to
  --old <old>             Specify the old version to compare to
  --platform <platform>   The platform to build the project for (iOS/macOS)
  --scheme <scheme>       [Optional] Which scheme to build (Needed when
                          comparing 2 xcode projects)
  --swift-interface-type <swift-interface-type>
                          [Optional] Specify the type of .swiftinterface you
                          want to compare (public/private) (default: public)
  --output <output>       [Optional] Where to output the result (File path)
  --log-output <log-output>
                          [Optional] Where to output the logs (File path)
  --log-level <log-level> [Optional] The log level to use during execution
                          (default: default)
  -h, --help              Show help information.
 ```
</details>
 
### From `.swiftinterface` to Output

**1.** Build 2 versions of your project with `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`
```bash
xcodebuild clean build \
    -scheme "YOUR_TARGET_NAME" \
    -derivedDataPath .build \
    -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
    -destination "generic/platform=iOS" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
```

**2.** Provide the `.swiftinterface` files to the public api diff
```bash
swift run public-api-diff \
    swift-interface \
    --new "new/path/to/project.swiftinterface" \
    --old "old/path/to/project.swiftinterface"
```
 
<details><summary><b>--help:</b></summary>
 
```
USAGE: public-api-diff swift-interface --new <new> --old <old> [--target-name <target-name>] [--old-version-name <old-version-name>] [--new-version-name <new-version-name>] [--output <output>] [--log-output <log-output>] [--log-level <log-level>]

OPTIONS:
  --new <new>             Specify the updated .swiftinterface file to compare to
  --old <old>             Specify the old .swiftinterface file to compare to
  --target-name <target-name>
                          [Optional] The name of your target/module to show in
                          the output
  --old-version-name <old-version-name>
                          [Optional] The name of your old version (e.g. v1.0 /
                          main) to show in the output
  --new-version-name <new-version-name>
                          [Optional] The name of your new version (e.g. v2.0 /
                          develop) to show in the output
  --output <output>       [Optional] Where to output the result (File path)
  --log-output <log-output>
                          [Optional] Where to output the logs (File path)
  --log-level <log-level> [Optional] The log level to use during execution
                          (default: default)
  -h, --help              Show help information.
```
</details>

### From `.framework` to Output

```bash
swift run public-api-diff \
    framework \
    --target-name "TargetName" \
    --new "new/path/to/project.framework" \
    --old "old/path/to/project.framework"
```

<details><summary><b>--help:</b></summary>

```
USAGE: public-api-diff framework --new <new> --old <old> --target-name <target-name> [--swift-interface-type <swift-interface-type>] [--old-version-name <old-version-name>] [--new-version-name <new-version-name>] [--output <output>] [--log-output <log-output>] [--log-level <log-level>]

OPTIONS:
  --new <new>             Specify the updated .framework to compare to
  --old <old>             Specify the old .framework to compare to
  --target-name <target-name>
                          The name of your target/module to show in the output
  --swift-interface-type <swift-interface-type>
                          [Optional] Specify the type of .swiftinterface you
                          want to compare (public/private) (default: public)
  --old-version-name <old-version-name>
                          [Optional] The name of your old version (e.g. v1.0 /
                          main) to show in the output
  --new-version-name <new-version-name>
                          [Optional] The name of your new version (e.g. v2.0 /
                          develop) to show in the output
  --output <output>       [Optional] Where to output the result (File path)
  --log-output <log-output>
                          [Optional] Where to output the logs (File path)
  --log-level <log-level> [Optional] The log level to use during execution
                          (default: default)
  -h, --help              Show help information.
```
</details>

## Release Build
### Create
```bash
swift build --configuration release
```

### Run
```bash
./public-api-diff \
    project \
    --new "develop~https://github.com/Adyen/adyen-ios.git" \ 
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git"
```
```bash
./public-api-diff \
    swift-interface \
    --new "new/path/to/project.swiftinterface" \
    --old "old/path/to/project.swiftinterface"
```
```bash
./public-api-diff \
    framework \
    --target-name "TargetName" \
    --new "new/path/to/project.framework" \
    --old "old/path/to/project.framework"
```

## Output Format

The tool generates a Markdown report showing all public API changes, organized by module/target:

```markdown
# 👀 3 public changes detected
_Comparing `develop` to `5.12.0`_

---
## `ModuleName`
#### ❇️ Added
\`\`\`swift
public func newFunction()
\`\`\`
#### 🔀 Changed
\`\`\`swift
// From
public func existingFunction(param: String)

// To
public func existingFunction(param: String, newParam: Int)
\`\`\`
#### 😶‍🌫️ Removed
\`\`\`swift
public func deprecatedFunction()
\`\`\`
```

The output can be written to a file using the `--output` flag or printed to stdout.

### JSON output
Use `--format json` (default: `markdown`) on `project`, `swift-interface` and `framework` to get a machine readable report instead:

```bash
public-api-diff swift-interface --old old.swiftinterface --new new.swiftinterface --target-name MyModule --format json
public-api-diff project --old main --new develop --platform iOS --format json --output report.json
```

- With `--format json` stdout only contains the JSON document, so it can be piped (`… --format json | jq`).
- In JSON mode the tool exits with a non-zero status on errors (and writes no output). The `markdown` mode keeps exiting with `0`.
- The output is deterministic: the same input always results in byte-identical output.
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
        "after": "public func reload(animated: Swift.Bool)",
        "details": [],
        "conditions": []
      }
    ]
  }
}
```

## Github Action
The public-api-diff can be used easily via the provided github action, which creates a comment on a PR (if applicable) and also adds it to the Github step summary.
```bash
- name: 🔍 Detect Changes
  uses: Adyen/adyen-swift-public-api-diff@0.12.0
  with:
    platform: "iOS"
    new: "develop~https://github.com/Adyen/adyen-ios.git"
    old: "5.12.0~https://github.com/Adyen/adyen-ios.git"
```
See: [example workflow](https://github.com/Adyen/adyen-swift-public-api-diff/blob/main/Examples/github-workflow.yml)

## Alternatives
- **swift-api-digester**
  - `xcrun swift-api-digester -dump-sdk`
  - `xcrun swift-api-digester -diagnose-sdk`

## Projects using `public-api-diff`
- [Adyen iOS Checkout](https://github.com/Adyen/adyen-ios)

## Inspiration
 - https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
   - For parsing swift files using [swift-syntax](https://github.com/swiftlang/swift-syntax)'s [`SyntaxVisitor`](https://github.com/swiftlang/swift-syntax/blob/main/Sources/SwiftSyntax/generated/SyntaxVisitor.swift)

## Support
If you have a feature request, or spotted a bug or a technical problem, create a GitHub issue.

## License    
MIT license. For more information, see the LICENSE file.
