[![🧪 Run Tests](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml)

# Swift Public API diff

This tool allows comparing 2 versions of a swift (sdk) project and lists all changes in a human readable way.

It makes use of `.swiftinterface` files that get produced during the archiving of a swift project and parses them using [`swift-syntax`](https://github.com/swiftlang/swift-syntax).

## Usage
 
### From Project to Output

```
swift run public-api-diff
    project
    --new "develop~https://github.com/Adyen/adyen-ios.git"
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git"
```

<details><summary><b>--help:</b></summary>

```
USAGE: public-api-diff project --new <new> --old <old> [--scheme <scheme>] [--swift-interface-type <swift-interface-type>] [--output <output>] [--log-output <log-output>] [--log-level <log-level>]

OPTIONS:
  --new <new>             Specify the updated version to compare to
  --old <old>             Specify the old version to compare to
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
 
```
swift run public-api-diff
    swift-interface
    --new "new/path/to/project.swiftinterface" 
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

```
swift run public-api-diff
    framework
    --target-name "TargetName"
    --new "new/path/to/project.framework" 
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

## How to create a release build
```
swift build --configuration release
```

## Run release build
```
./public-api-diff
    project
    --new "develop~https://github.com/Adyen/adyen-ios.git" 
    --old "5.12.0~https://github.com/Adyen/adyen-ios.git"
    
./public-api-diff
    swift-interface
    --new "new/path/to/project.swiftinterface" 
    --old "old/path/to/project.swiftinterface"
    
./public-api-diff
    framework
    --target-name "TargetName"
    --new "new/path/to/project.framework" 
    --old "old/path/to/project.framework"
```

# Alternatives
- **swift-api-digester**
  - `xcrun swift-api-digester -dump-sdk`
  - `xcrun swift-api-digester -diagnose-sdk`

# Inspiration
 - https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
   - For parsing swift files using [swift-syntax](https://github.com/swiftlang/swift-syntax)'s [`SyntaxVisitor`](https://github.com/swiftlang/swift-syntax/blob/main/Sources/SwiftSyntax/generated/SyntaxVisitor.swift)
