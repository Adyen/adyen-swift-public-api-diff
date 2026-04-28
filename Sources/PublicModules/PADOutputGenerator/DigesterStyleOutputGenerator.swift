//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

/// Generates output in a format similar to swift-api-digester for compatibility
public struct DigesterStyleOutputGenerator: OutputGenerating {

    public init() {}

    /// Generates digester-style output from the provided information
    public func generate(
        from changesPerTarget: [String: [Change]],
        allTargets: [String]?,
        oldVersionName: String?,
        newVersionName: String?,
        platform: String?,
        warnings: [String]
    ) throws -> String {

        var output = [String]()

        // Group changes by category
        var genericSignatureChanges = [String]()
        var removedDecls = [String]()
        var renamedDecls = [String]()
        var typeChanges = [String]()
        var protocolConformanceChanges = [String]()
        var protocolRequirementChanges = [String]()
        var addedDecls = [String]()

        // Process each target
        for targetName in changesPerTarget.keys.sorted() {
            guard let changes = changesPerTarget[targetName] else { continue }

            for change in changes {
                let fullPath = Self.buildFullPath(targetName: targetName, parentPath: change.parentPath)

                switch change.changeType {
                case .addition(let description):
                    addedDecls.append(Self.formatAddition(description: description, fullPath: fullPath))

                case .removal(let description):
                    removedDecls.append(Self.formatRemoval(description: description, fullPath: fullPath))

                case .modification(let oldDescription, let newDescription):
                    Self.categorizeModification(
                        oldDescription: oldDescription,
                        newDescription: newDescription,
                        fullPath: fullPath,
                        listOfChanges: change.listOfChanges,
                        genericSignatureChanges: &genericSignatureChanges,
                        renamedDecls: &renamedDecls,
                        typeChanges: &typeChanges,
                        protocolConformanceChanges: &protocolConformanceChanges,
                        protocolRequirementChanges: &protocolRequirementChanges
                    )
                }
            }
        }

        // Output in digester format with categories
        output.append("/* Generic Signature Changes */")
        output.append(contentsOf: genericSignatureChanges.sorted())

        output.append("")
        output.append("/* RawRepresentable Changes */")

        output.append("")
        output.append("/* Removed Decls */")
        output.append(contentsOf: removedDecls.sorted())

        output.append("")
        output.append("/* Moved Decls */")

        output.append("")
        output.append("/* Renamed Decls */")
        output.append(contentsOf: renamedDecls.sorted())

        output.append("")
        output.append("/* Type Changes */")
        output.append(contentsOf: typeChanges.sorted())

        output.append("")
        output.append("/* Decl Attribute changes */")

        output.append("")
        output.append("/* Fixed-layout Type Changes */")

        output.append("")
        output.append("/* Protocol Conformance Change */")
        output.append(contentsOf: protocolConformanceChanges.sorted())

        output.append("")
        output.append("/* Protocol Requirement Change */")
        output.append(contentsOf: protocolRequirementChanges.sorted())

        output.append("")
        output.append("/* Class Inheritance Change */")

        output.append("")
        output.append("/* Added Decls */")
        output.append(contentsOf: addedDecls.sorted())

        output.append("")
        output.append("/* Others */")

        return output.joined(separator: "\n")
    }
}

// MARK: - Privates

private extension DigesterStyleOutputGenerator {

    static func buildFullPath(targetName: String, parentPath: String?) -> String {
        // Build path similar to swift-api-digester (without module prefix in most cases)
        if let parentPath, !parentPath.isEmpty {
            return parentPath
        }
        return ""
    }

    static func formatAddition(description: String, fullPath: String) -> String {
        let declType = extractDeclType(from: description)
        let name = extractDeclName(from: description)
        let qualifiedName = fullPath.isEmpty ? name : "\(fullPath).\(name)"
        return "\(declType) \(qualifiedName) has been added"
    }

    static func formatRemoval(description: String, fullPath: String) -> String {
        let declType = extractDeclType(from: description)
        let name = extractDeclName(from: description)
        let qualifiedName = fullPath.isEmpty ? name : "\(fullPath).\(name)"
        return "\(declType) \(qualifiedName) has been removed"
    }

    static func categorizeModification(
        oldDescription: String,
        newDescription: String,
        fullPath: String,
        listOfChanges: [String],
        genericSignatureChanges: inout [String],
        renamedDecls: inout [String],
        typeChanges: inout [String],
        protocolConformanceChanges: inout [String],
        protocolRequirementChanges: inout [String]
    ) {
        let declType = extractDeclType(from: oldDescription)
        let oldName = extractDeclName(from: oldDescription)
        let newName = extractDeclName(from: newDescription)
        let qualifiedName = fullPath.isEmpty ? oldName : "\(fullPath).\(oldName)"

        // Analyze the list of changes to categorize them
        for changeDescription in listOfChanges {
            let lowercased = changeDescription.lowercased()

            if lowercased.contains("generic parameter") || lowercased.contains("generic where clause") {
                let oldGenericSig = extractGenericSignature(from: oldDescription)
                let newGenericSig = extractGenericSignature(from: newDescription)
                genericSignatureChanges.append("\(declType) \(qualifiedName) has generic signature change from \(oldGenericSig) to \(newGenericSig)")
            }

            if lowercased.contains("parameter") && !lowercased.contains("generic parameter") {
                // Parameter changes might indicate a rename
                let oldParams = extractParameters(from: oldDescription)
                let newParams = extractParameters(from: newDescription)
                if oldParams != newParams {
                    let newQualifiedName = fullPath.isEmpty ? newName : "\(fullPath).\(newName)"
                    renamedDecls.append("\(declType) \(qualifiedName) has been renamed to \(declType) \(newQualifiedName)")
                }
            }

            if lowercased.contains("type from") || lowercased.contains("modified type") {
                typeChanges.append("\(declType) \(qualifiedName) has declared type change")
            }

            if lowercased.contains("inheritance") && lowercased.contains("protocol") {
                if let addedProtocol = extractAddedProtocol(from: changeDescription) {
                    if declType == "Protocol" {
                        protocolConformanceChanges.append("Protocol \(qualifiedName) has added inherited protocol \(addedProtocol)")
                    }
                }
            }

            if lowercased.contains("associated type") && lowercased.contains("added") {
                if let associatedType = extractAssociatedType(from: changeDescription) {
                    protocolRequirementChanges.append("AssociatedType \(qualifiedName).\(associatedType) has been added as a protocol requirement")
                }
            }
        }

        // If no specific categorization was made, check for simple type changes
        if listOfChanges.isEmpty || (!genericSignatureChanges.contains { $0.contains(qualifiedName) } &&
            !typeChanges.contains { $0.contains(qualifiedName) }) {
            // Generic fallback for modifications without detailed change info
            if oldDescription != newDescription {
                typeChanges.append("\(declType) \(qualifiedName) has declaration change")
            }
        }
    }

    static func extractDeclType(from description: String) -> String {
        // Extract the declaration type (Func, Var, Struct, Class, etc.)
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.components(separatedBy: .whitespaces)

        // Look for common declaration keywords
        for component in components {
            switch component {
            case "func": return "Func"
            case "var", "let": return "Var"
            case "struct": return "Struct"
            case "class": return "Class"
            case "enum": return "Enum"
            case "protocol": return "Protocol"
            case "actor": return "Actor"
            case "typealias": return "TypeAlias"
            case "init": return "Constructor"
            case "subscript": return "Subscript"
            case "case": return "EnumElement"
            default: continue
            }
        }

        return "Decl"
    }

    static func extractDeclName(from description: String) -> String {
        // Extract the name from the declaration
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle different declaration types
        if trimmed.contains("func ") {
            return extractFunctionName(from: trimmed)
        } else if trimmed.contains("var ") || trimmed.contains("let ") {
            return extractVarName(from: trimmed)
        } else if trimmed.contains("struct ") || trimmed.contains("class ") ||
                  trimmed.contains("enum ") || trimmed.contains("protocol ") ||
                  trimmed.contains("actor ") {
            return extractTypeName(from: trimmed)
        } else if trimmed.contains("init") {
            return extractInitName(from: trimmed)
        } else if trimmed.contains("subscript") {
            return "subscript"
        } else if trimmed.contains("case ") {
            return extractEnumCaseName(from: trimmed)
        }

        return "unknown"
    }

    static func extractFunctionName(from description: String) -> String {
        // Extract function name with parameters
        if let funcRange = description.range(of: "func ") {
            let afterFunc = description[funcRange.upperBound...]
            if let parenIndex = afterFunc.firstIndex(of: "(") {
                let name = String(afterFunc[..<parenIndex])
                let params = extractParameters(from: description)
                return params.isEmpty ? "\(name)()" : "\(name)(\(params))"
            }
        }
        return "unknownFunc()"
    }

    static func extractVarName(from description: String) -> String {
        let keywords = ["var ", "let "]
        for keyword in keywords {
            if let range = description.range(of: keyword) {
                let afterKeyword = description[range.upperBound...]
                if let colonIndex = afterKeyword.firstIndex(of: ":") {
                    return String(afterKeyword[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                }
                if let spaceIndex = afterKeyword.firstIndex(of: " ") {
                    return String(afterKeyword[..<spaceIndex]).trimmingCharacters(in: .whitespaces)
                }
                return String(afterKeyword).trimmingCharacters(in: .whitespaces)
            }
        }
        return "unknownVar"
    }

    static func extractTypeName(from description: String) -> String {
        let keywords = ["struct ", "class ", "enum ", "protocol ", "actor "]
        for keyword in keywords {
            if let range = description.range(of: keyword) {
                let afterKeyword = description[range.upperBound...]
                // Handle generics
                if let colonIndex = afterKeyword.firstIndex(of: ":") {
                    return String(afterKeyword[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                }
                if let braceIndex = afterKeyword.firstIndex(of: "{") {
                    return String(afterKeyword[..<braceIndex]).trimmingCharacters(in: .whitespaces)
                }
                if let spaceIndex = afterKeyword.firstIndex(of: " ") {
                    return String(afterKeyword[..<spaceIndex]).trimmingCharacters(in: .whitespaces)
                }
                return String(afterKeyword).components(separatedBy: .newlines)[0].trimmingCharacters(in: .whitespaces)
            }
        }
        return "UnknownType"
    }

    static func extractInitName(from description: String) -> String {
        let params = extractParameters(from: description)
        return params.isEmpty ? "init()" : "init(\(params))"
    }

    static func extractEnumCaseName(from description: String) -> String {
        if let range = description.range(of: "case ") {
            let afterCase = description[range.upperBound...]
            if let newlineIndex = afterCase.firstIndex(of: "\n") {
                return String(afterCase[..<newlineIndex]).trimmingCharacters(in: .whitespaces)
            }
            return String(afterCase).trimmingCharacters(in: .whitespaces)
        }
        return "unknownCase"
    }

    static func extractParameters(from description: String) -> String {
        // Extract parameter labels for function signature
        guard let openParen = description.firstIndex(of: "("),
              let closeParen = description.lastIndex(of: ")") else {
            return ""
        }

        let paramsString = String(description[description.index(after: openParen)..<closeParen])
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        if paramsString.isEmpty || paramsString.trimmingCharacters(in: .whitespaces).isEmpty {
            return ""
        }

        // Handle simple cases first
        let trimmed = paramsString.trimmingCharacters(in: .whitespaces)
        
        // Split by comma, but be careful with nested types
        var params = [String]()
        var current = ""
        var depth = 0
        
        for char in trimmed {
            if char == "<" || char == "(" || char == "[" {
                depth += 1
                current.append(char)
            } else if char == ">" || char == ")" || char == "]" {
                depth -= 1
                current.append(char)
            } else if char == "," && depth == 0 {
                params.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            params.append(current)
        }

        let labels = params.compactMap { param -> String? in
            let trimmed = param.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return nil }
            
            // Extract parameter label (before the colon or first word)
            let components = trimmed.split(separator: " ", maxSplits: 2)
            if let first = components.first {
                let label = String(first)
                if label == "_" {
                    return "_"
                }
                // Remove trailing colon if present
                return label.hasSuffix(":") ? String(label.dropLast()) : label
            }
            return nil
        }

        return labels.joined(separator: ":")
    }

    static func extractGenericSignature(from description: String) -> String {
        // Extract generic signature like <T where T : Swift.Equatable>
        // Also include where clauses that appear after the generic params
        
        var genericSig = ""
        
        // First, find the generic parameters in angle brackets
        if let openAngle = description.firstIndex(of: "<") {
            var depth = 0
            var closeAngle: String.Index?

            for index in description[openAngle...].indices {
                let char = description[index]
                if char == "<" {
                    depth += 1
                } else if char == ">" {
                    depth -= 1
                    if depth == 0 {
                        closeAngle = index
                        break
                    }
                }
            }

            if let closeAngle {
                genericSig = String(description[openAngle...closeAngle])
                    .replacingOccurrences(of: "\n", with: " ")
            }
        }
        
        // Now check for where clause
        if let whereRange = description.range(of: " where ") {
            let afterWhere = description[whereRange.upperBound...]
            // Find the end of the where clause (before { or end of line)
            var whereClause = ""
            if let braceIndex = afterWhere.firstIndex(of: "{") {
                whereClause = String(afterWhere[..<braceIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                // Take until newline or end
                if let newlineIndex = afterWhere.firstIndex(of: "\n") {
                    whereClause = String(afterWhere[..<newlineIndex])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    whereClause = String(afterWhere)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            if !whereClause.isEmpty {
                if genericSig.isEmpty {
                    genericSig = " where \(whereClause)"
                } else {
                    // Insert where clause before the closing >
                    if genericSig.hasSuffix(">") {
                        genericSig = String(genericSig.dropLast()) + " where \(whereClause)>"
                    } else {
                        genericSig += " where \(whereClause)"
                    }
                }
            }
        }
        
        return genericSig
    }

    static func extractAddedProtocol(from changeDescription: String) -> String? {
        // Extract protocol name from "Added inheritance `ProtocolName`"
        if let range = changeDescription.range(of: "`") {
            let afterTick = changeDescription[range.upperBound...]
            if let endTick = afterTick.firstIndex(of: "`") {
                return String(afterTick[..<endTick])
            }
        }
        return nil
    }

    static func extractAssociatedType(from changeDescription: String) -> String? {
        // Extract associated type name from "Added primary associated type `TypeName`"
        if let range = changeDescription.range(of: "`") {
            let afterTick = changeDescription[range.upperBound...]
            if let endTick = afterTick.firstIndex(of: "`") {
                return String(afterTick[..<endTick])
            }
        }
        return nil
    }
}
