# Swift Public API diff

This tool allows comparing 2 versions of a swift package project and lists all changes in a human readable way.

It makes use of `xcrun swift-api-digester -dump-sdk` to create a dump of the public api of your swift package and then runs it through a custom parser to process them.

Alternatively you could use `xcrun swift-api-digester -diagnose-sdk` and pass the abi dumps into it.

## How it works

![image](https://github.com/user-attachments/assets/cc04d21a-06f6-42bc-8e73-4aef7af21d7a)


### Project Builder

Builds the swift package project which is required for the next step to run the `xcrun swift-api-digester -dump-sdk`

### ABIGenerator

Makes use of `xcrun swift-api-digester -dump-sdk` to "dump" the public interface into an abi.json file.

### SDKDumpGenerator

Parses the abi.json files into an `SDKDump` object

### SDKDumpAnalyzer

Analyzes 2 `SDKDump` objects and detects `addition`s & `removal`s.

### ChangeConsolidator

The `ChangeConsolidator` takes 2 independent changes (`addition` & `removal`) and tries to match them based on the name, declKind and parent.

| Match |
| --- |
| ![image](https://github.com/user-attachments/assets/f057c160-f85d-45af-b08f-203b89e43b41) |

| No Match | Potentially false positive |
| --- | --- |
| ![image](https://github.com/user-attachments/assets/5ae3b624-b32a-41cc-9026-8ba0117cec57) | ![image](https://github.com/user-attachments/assets/a7e60605-fc1c-49ef-a203-d6a5466a6fda) |

### OutputGenerator

Receives a dictionary of `[{SCOPE_NAME}: [Change]]` and processes them into a human readable format.

## Inspiration
- SwiftInterfaceParser: https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
