//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

/// Allows generation of human readable output from the provided information
public struct MarkdownOutputGenerator: OutputGenerating {

    public init() {}

    /// Generates human readable output from the provided information
    public func generate(
        from changesPerTarget: [String: [Change]],
        allTargets: [String]?,
        oldVersionName: String?,
        newVersionName: String?,
        warnings: [String]
    ) -> String {

        let separator = "\n---"
        let changes = Self.changeLines(changesPerModule: changesPerTarget)

        var lines = [
            Self.title(changesPerTarget: changesPerTarget, allTargets: allTargets)
        ]

        if let oldVersionName, let newVersionName {
            lines += [Self.repoInfo(oldVersionName: oldVersionName, newVersionName: newVersionName)]
        }
        
        if !changes.isEmpty {
            lines += [Self.totalChangesBreakdown(changesPerTarget: changesPerTarget)]
        }

        lines += [separator]

        if !warnings.isEmpty {
            lines += Self.warningInfo(for: warnings) + [separator]
        }

        if !changes.isEmpty {
            lines += changes + [separator]
        }

        if let allTargets, !allTargets.isEmpty {
            lines += [
                Self.analyzedModulesInfo(allTargets: allTargets)
            ]
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Privates

private extension MarkdownOutputGenerator {

    static func title(
        changesPerTarget: [String: [Change]],
        allTargets: [String]?
    ) -> String {
        
        if let allTargets, allTargets.isEmpty {
            // We got targets but the list is empty -> Show an error
            return "# ‼️ No analyzable targets detected"
        }

        if changesPerTarget.keys.isEmpty {
            return "# ✅ No changes detected"
        }

        let totalChangeCount = changesPerTarget.totalCount(for: .allChanges)
        
        if changesPerTarget.potentiallyBreakingChangesCount > 0 {
            return "# ⚠️ \(totalChangeCount) public \(totalChangeCount == 1 ? "change" : "changes") detected ⚠️"
        } else {
            return "# 👀 \(totalChangeCount) public \(totalChangeCount == 1 ? "change" : "changes") detected"
        }
    }
    
    static func totalChangesBreakdown(changesPerTarget: [String: [Change]]) -> String {
        
        let additions = changesPerTarget.totalCount(for: .additions)
        let changes = changesPerTarget.totalCount(for: .modifications)
        let removals = changesPerTarget.totalCount(for: .removals)
        
        guard additions + changes + removals > 0 else { return "" }
        
        var breakdown = "<table>"
        if additions > 0 { breakdown += "<tr><td>❇️</td><td><b>\(additions) \(additions == 1 ? "Addition" : "Additions")</b></td></tr>" }
        if changes > 0 { breakdown += "<tr><td>🔀</td><td><b>\(changes) \(changes == 1 ? "Modification" : "Modifications")</b></td></tr>" }
        if removals > 0 { breakdown += "<tr><td>❌</td><td><b>\(removals) \(removals == 1 ? "Removal" : "Removals")</b></td></tr>" }
        breakdown += "</table>"
        return breakdown
    }

    static func repoInfo(oldVersionName: String, newVersionName: String) -> String {
        "_Comparing `\(newVersionName)` to `\(oldVersionName)`_"
    }

    static func analyzedModulesInfo(allTargets: [String]) -> String {
        "**Analyzed targets:** \(allTargets.joined(separator: ", "))"
    }

    static func warningInfo(for warnings: [String]) -> [String] {
        warnings.map { "> [!WARNING]\n> \($0)" }
    }

    static func changeLines(changesPerModule: [String: [Change]]) -> [String] {
        var lines = [String]()

        changesPerModule.keys.sorted().forEach { targetName in
            guard let changesForTarget = changesPerModule[targetName], !changesPerModule.isEmpty else { return }

            if !targetName.isEmpty {
                lines.append("## `\(targetName)`")
            }

            var groupedChanges = [String: [Change]]()

            changesForTarget.forEach {
                groupedChanges[$0.parentPath ?? ""] = (groupedChanges[$0.parentPath ?? ""] ?? []) + [$0]
            }

            groupedChanges.keys.sorted().forEach { parent in
                guard let changes = groupedChanges[parent], !changes.isEmpty else { return }

                if !parent.isEmpty {
                    lines.append("### `\(parent)`")
                }

                let additionLines = changeSectionLines(
                    title: "#### ❇️ Added",
                    changes: changes.filter(\.changeType.isAddition)
                )
                let changeLines = changeSectionLines(
                    title: "#### 🔀 Modified",
                    changes: changes.filter(\.changeType.isModification)
                )
                let removalLines = changeSectionLines(
                    title: "#### ❌ Removed",
                    changes: changes.filter(\.changeType.isRemoval)
                )

                if !additionLines.isEmpty { lines += additionLines }
                if !changeLines.isEmpty { lines += changeLines }
                if !removalLines.isEmpty { lines += removalLines }
            }
        }

        return lines
    }
}

private extension MarkdownOutputGenerator {

    static func changeSectionLines(title: String, changes: [Change]) -> [String] {
        if changes.isEmpty { return [] }

        var lines = [title]
        changes.sorted { lhs, rhs in description(for: lhs) < description(for: rhs) }.forEach {
            // We're using `javascript` as it produces the nicest looking markdown output on Github
            // `swift` is available but sometimes produces unexpected syntax highlighting
            lines.append("```javascript")
            lines.append(description(for: $0))

            if !$0.listOfChanges.isEmpty {
                lines.append("")
                lines.append("/**")
                lines.append("Changes:")
                $0.listOfChanges.forEach {
                    lines.append("- \($0)")
                }
                lines.append("*/")
            }

            lines.append("```")
        }
        return lines
    }

    static func description(for change: Change) -> String {
        switch change.changeType {
        case let .addition(description):
            return description
        case let .removal(description):
            return description
        case let .modification(before, after):
            return "// From\n\(before)\n\n// To\n\(after)"
        }
    }
}

private extension [String: [Change]] {

    enum ChangeCountType {
        case allChanges
        case additions
        case modifications
        case removals
    }
    
    var potentiallyBreakingChangesCount: Int {
        return totalCount(for: .modifications) + totalCount(for: .removals)
    }
    
    func totalCount(for countType: ChangeCountType) -> Int {
        var totalChangeCount = 0
        keys.forEach { targetName in
            switch countType {
            case .allChanges:
                totalChangeCount += self[targetName]?.count ?? 0
            case .additions:
                totalChangeCount += self[targetName]?.reduce(0, { $0 + ($1.changeType.isAddition ? 1 : 0) }) ?? 0
            case .modifications:
                totalChangeCount += self[targetName]?.reduce(0, { $0 + ($1.changeType.isModification ? 1 : 0) }) ?? 0
            case .removals:
                totalChangeCount += self[targetName]?.reduce(0, { $0 + ($1.changeType.isRemoval ? 1 : 0) }) ?? 0
            }
        }
        return totalChangeCount
    }
}
