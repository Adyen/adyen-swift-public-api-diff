 [![🧪 Run Tests](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Adyen/adyen-swift-public-api-diff/actions/workflows/run-tests.yml)

 # Swift Public API diff

 This tool allows comparing 2 versions of a swift (sdk) project and lists all changes in a human readable way.

 It makes use of `.swiftinterface` files that get produced during the archiving of a swift project and parses them using [`swift-syntax`](https://github.com/swiftlang/swift-syntax).

 ## Usage

 ```
 USAGE: public-api-diff --new <new> --old <old> [--output <output>] [--log-output <log-output>] [--scheme <scheme>]

 OPTIONS:
   --new <new>             Specify the updated version to compare to
   --old <old>             Specify the old version to compare to
   --output <output>       Where to output the result (File path)
   --log-output <log-output>
                           Where to output the logs (File path)
   --scheme <scheme>       Which scheme to build (Needed when comparing 2 xcode projects)
   -h, --help              Show help information.
 ```

### Run as debug build
```
swift run public-api-diff 
    --new "some/local/path" 
    --old "develop~https://github.com/some/repository" 
    --output "path/to/output.md"
```

### How to create a release build
```
swift build --configuration release
```

### Run release build
```
./public-api-diff
    --new "some/local/path" 
    --old "develop~https://github.com/some/repository" 
    --output "path/to/output.md"
```

# Alternatives
- **swift-api-digester**
  - `xcrun swift-api-digester -dump-sdk`
  - `xcrun swift-api-digester -diagnose-sdk`

# Inspiration
 - https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
   - For parsing swift files using [swift-syntax](https://github.com/swiftlang/swift-syntax)'s [`SyntaxVisitor`](https://github.com/swiftlang/swift-syntax/blob/main/Sources/SwiftSyntax/generated/SyntaxVisitor.swift)
