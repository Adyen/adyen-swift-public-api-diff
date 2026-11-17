//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import SwiftSyntax

/// Handling of `#if` blocks in interfaces
///
/// Interfaces guard declarations with compiler, language feature or platform checks and often spell
/// the same declaration again in an `#else` clause, e.g.
///
/// ```swift
/// #if compiler(>=5.3) && $TildeSendable
/// public struct S: ~Swift.Sendable { ... }
/// #else
/// public struct S { ... }
/// #endif
/// ```
///
/// Every clause is parsed. Declarations are tagged with the condition of their clause, so the variants
/// of a declaration are different elements and are only compared with the same variant of the other version.
/// The condition is stored as the first entry(s) of the element's `attributes` (e.g. `#if $TildeSendable`,
/// or `#if !(compiler(>=5.3) && $TildeSendable)` for the `#else` clause) which makes it part of the description.
///
/// Members inherit the conditions of their enclosing declarations (see ``SwiftInterfaceElement/allConditions``).
///
/// Attributes inside an `#if` of an attribute list are kept per clause, e.g. `#if $NonexhaustiveAttribute @nonexhaustive #endif`.
enum ConditionalCompilation {

    private static let conditionPrefix = "#if "
    private static let attributeSuffix = " #endif"

    /// The attribute tagging a declaration with the condition of its clause
    static func attribute(for condition: String) -> String {
        "\(conditionPrefix)\(condition)"
    }

    /// The condition if the attribute tags a declaration (see ``attribute(for:)``)
    static func condition(of attribute: String) -> String? {
        guard attribute.hasPrefix(conditionPrefix), !attribute.hasSuffix(attributeSuffix) else { return nil }
        return String(attribute.dropFirst(conditionPrefix.count))
    }

    /// The conditions tagging a declaration, outermost first
    static func conditions(of attributes: [String]) -> [String] {
        attributes.compactMap(condition(of:))
    }

    /// Prepends the condition attributes for `conditions` that `attributes` doesn't have yet
    static func attributes(_ attributes: [String], adding conditions: [String]) -> [String] {
        let existing = Set(Self.conditions(of: attributes))
        let added = conditions.filter { !existing.contains($0) }.map(attribute(for:))
        guard !added.isEmpty else { return attributes }
        let ownConditions = attributes.prefix { condition(of: $0) != nil }
        return ownConditions + added + attributes.dropFirst(ownConditions.count)
    }

    /// An attribute that is only applied under `condition` (from an `#if` inside an attribute list)
    static func conditionalAttribute(_ attribute: String, condition: String) -> String {
        "\(conditionPrefix)\(condition) \(attribute)\(attributeSuffix)"
    }

    /// The clauses of an `#if` with the condition under which each of them applies
    ///
    /// e.g. `#if A ... #elseif B ... #else ... #endif` → `A`, `!A && B`, `!A && !B`
    static func clauses(of node: IfConfigDeclSyntax) -> [(clause: IfConfigClauseSyntax, condition: String)] {
        var previousConditions = [String]()
        return node.clauses.map { clause in
            let negatedPrevious = previousConditions.map(negated)
            guard let condition = clause.condition.map({ normalized($0.trimmedDescription) }) else {
                return (clause, negatedPrevious.joined(separator: " && "))
            }
            previousConditions.append(condition)
            return (clause, (negatedPrevious + [parenthesizedIfNeeded(condition)]).joined(separator: " && "))
        }
    }

    private static func normalized(_ condition: String) -> String {
        condition.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Whether the condition is a single term (e.g. `$Feature`, `compiler(>=5.3)`, `!os(iOS)`)
    private static func isSingleTerm(_ condition: String) -> Bool {
        condition.range(of: "^!?[A-Za-z0-9_$]+(\\([^()]*\\))?$", options: .regularExpression) != nil
    }

    private static func parenthesizedIfNeeded(_ condition: String) -> String {
        isSingleTerm(condition) || !condition.contains("||") ? condition : "(\(condition))"
    }

    private static func negated(_ condition: String) -> String {
        guard isSingleTerm(condition) else { return "!(\(condition))" }
        return condition.hasPrefix("!") ? String(condition.dropFirst()) : "!\(condition)"
    }
}

extension SwiftInterfaceElement {

    /// The conditions of the `#if` clauses the element itself is declared in (see ``ConditionalCompilation``)
    var conditions: [String] {
        guard let attributedElement = self as? SwiftInterfaceAttributedElement else { return [] }
        return ConditionalCompilation.conditions(of: attributedElement.attributes)
    }

    /// The conditions of the element including the ones of its enclosing declarations, outermost first
    var allConditions: [String] {
        var conditions = [String]()
        var element: (any SwiftInterfaceElement)? = self
        while let current = element {
            conditions = current.conditions + conditions
            element = current.parent
        }
        return conditions.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
    }
}

// MARK: - Rendering

extension ConditionalCompilation {

    /// The description of an element for the output, with its conditions as `#if … #endif` blocks
    /// instead of the attributes used for comparing (see ``attribute(for:)``)
    ///
    /// The element is wrapped in all of its conditions (including the ones of its enclosing declarations),
    /// children declared under the same conditions share one block.
    ///
    /// ```swift
    /// #if compiler(>=5.3) && $TildeSendable
    /// public struct Shape: ~Swift.Sendable {
    ///   #if !$Embedded
    ///   public func area() -> Swift.Double
    ///   public func describe() -> Swift.String
    ///   #endif
    /// }
    /// #endif
    /// ```
    static func renderedDescription(of element: any SwiftInterfaceElement, recursive: Bool) -> String {
        let description = recursive ? renderedRecursiveDescription(of: element) : descriptionWithoutConditions(of: element)
        return wrapped(description, in: element.allConditions)
    }

    /// Wraps the text in an `#if` block (conditions combined with `&&`)
    static func wrapped(_ text: String, in conditions: [String]) -> String {
        guard !conditions.isEmpty else { return text }
        return "\(conditionPrefix)\(conditions.joined(separator: " && "))\n\(text)\n#endif"
    }

    /// The element's description without the leading condition attributes,
    /// conditional attributes (see ``conditionalAttribute(_:condition:)``) are rendered as blocks
    private static func descriptionWithoutConditions(of element: any SwiftInterfaceElement) -> String {
        element.description
            .components(separatedBy: "\n")
            .drop { condition(of: $0) != nil }
            .map(renderedConditionalAttribute)
            .joined(separator: "\n")
    }

    /// `#if $X @attribute #endif` → `#if $X`, `@attribute`, `#endif` on separate lines (as declared in the interface)
    private static func renderedConditionalAttribute(_ line: String) -> String {
        guard let (attribute, condition) = splitConditionalAttribute(line) else { return line }
        return "\(conditionPrefix)\(condition)\n\(attribute)\n#endif"
    }

    /// Splits a conditional attribute (see ``conditionalAttribute(_:condition:)``) into the attribute and its condition
    static func splitConditionalAttribute(_ value: String) -> (attribute: String, condition: String)? {
        guard value.hasPrefix(conditionPrefix), value.hasSuffix(attributeSuffix),
              let attributeStart = value.range(of: " @") else { return nil }
        let condition = value[value.index(value.startIndex, offsetBy: conditionPrefix.count)..<attributeStart.lowerBound]
        let attribute = value[value.index(after: attributeStart.lowerBound)...].dropLast(attributeSuffix.count)
        return (String(attribute), String(condition))
    }

    /// An attribute for a list of changes, e.g. `` `@nonexhaustive` (`#if $NonexhaustiveAttribute`) ``
    static func describedAttribute(_ value: String) -> String {
        guard let (attribute, condition) = splitConditionalAttribute(value) else { return "`\(value)`" }
        return "`\(attribute)` (`\(conditionPrefix)\(condition)`)"
    }

    /// Mirrors `recursiveDescription()` with the children's conditions rendered as blocks
    private static func renderedRecursiveDescription(of element: any SwiftInterfaceElement) -> String {
        var description = descriptionWithoutConditions(of: element)
        // Conformance extensions (see `conformanceExtensionsDescription`) follow the type's body
        let conformanceExtensions = (element as? any SwiftInterfaceConformingElement)?
            .conformanceExtensionsDescription(incl: Set(SwiftInterfaceElementDescriptionToken.allCases))
        if let conformanceExtensions, description.hasSuffix(conformanceExtensions) {
            description.removeLast(conformanceExtensions.count)
        }

        if !element.children.isEmpty {
            description.append(" {")
            let children = element.children
                .map { (conditions: $0.conditions, description: renderedRecursiveDescription(of: $0)) }
                .sorted { ($0.conditions.joined(separator: "\n"), $0.description) < ($1.conditions.joined(separator: "\n"), $1.description) }

            var index = children.startIndex
            while index < children.endIndex {
                let conditions = children[index].conditions
                let group = children[index...].prefix { $0.conditions == conditions }
                let block = wrapped(group.map(\.description).joined(separator: "\n"), in: conditions)
                description.append("\n\(indented(block))")
                index += group.count
            }
            description.append("\n}")
        }

        if let conformanceExtensions {
            description.append(conformanceExtensions)
        }
        return description
    }

    private static func indented(_ text: String) -> String {
        text.components(separatedBy: "\n").map { "  \($0)" }.joined(separator: "\n")
    }
}
