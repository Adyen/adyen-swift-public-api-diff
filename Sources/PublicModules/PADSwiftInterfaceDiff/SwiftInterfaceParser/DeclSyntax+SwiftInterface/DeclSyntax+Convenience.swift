//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

extension SyntaxCollection {

    /// Produces a description where all elements in the list are mapped to their `trimmedDescription`
    var sanitizedList: [String] {
        self.map(\.trimmedDescription)
    }
}

extension AttributeListSyntax {

    private var translationTable: [String: String] {
        [
            "@_functionBuilder": "@resultBuilder"
        ]
    }
    
    private var excludedAttributes: Set<String> {
        [
            "@_hasMissingDesignatedInitializers",
            "@_inheritsConvenienceInitializers"
        ]
    }

    /// Produces a description where all elements in the list are mapped to their `trimmedDescription`
    ///
    /// Attributes inside an `#if` are kept per clause together with the clause's condition
    /// (e.g. `#if $NonexhaustiveAttribute @nonexhaustive #endif`, see ``ConditionalCompilation``)
    var sanitizedList: [String] {
        var descriptions: [String] = []
        var availabilityIndices: [Int] = []
        for element in self {
            if case let .ifConfigDecl(ifConfig) = element {
                descriptions += ConditionalCompilation.clauses(of: ifConfig).flatMap { clause, condition -> [String] in
                    guard case let .attributes(attributes) = clause.elements else { return [] }
                    return attributes.sanitizedList.map {
                        ConditionalCompilation.conditionalAttribute($0.sanitizingNewlinesAndSpaces, condition: condition)
                    }
                }
                continue
            }
            var description = element.trimmedDescription
            if case let .attribute(attribute) = element, attribute.attributeName.trimmedDescription == "available" {
                availabilityIndices.append(descriptions.count)
                description = normalizedAvailability(attribute).trimmedDescription
            }
            description = translationTable[description] ?? description
            if !excludedAttributes.contains(description) {
                descriptions.append(description)
            }
        }
        for (index, description) in zip(availabilityIndices, availabilityIndices.map { descriptions[$0] }.sorted()) {
            descriptions[index] = description
        }
        return descriptions
    }

    private func normalizedAvailability(_ attribute: AttributeSyntax) -> AttributeSyntax {
        guard case let .availability(arguments) = attribute.arguments,
              arguments.count > 2,
              let wildcard = arguments.last,
              case let .token(token) = wildcard.argument,
              token.text == "*" else {
            return attribute
        }
        let platforms = arguments.dropLast()
        // Only the shorthand platform list is order-independent. Keep the wildcard last.
        guard platforms.allSatisfy({
            if case .availabilityVersionRestriction = $0.argument { return true }
            return false
        }) else { return attribute }

        let ordered = platforms.sorted { $0.argument.trimmedDescription < $1.argument.trimmedDescription }
        let normalized = ordered.map { argument in
            argument.trimmed.with(\.trailingComma, .commaToken(trailingTrivia: .space))
        } + [wildcard.trimmed]
        return attribute.with(\.arguments, .availability(AvailabilityArgumentListSyntax(normalized)))
    }
}

extension InheritedTypeListSyntax {

    /// Produces a description where all elements in the list are mapped to their type's `trimmedDescription`
    var sanitizedList: [String] {
        self.map(\.type.trimmedDescription)
    }
}

extension AccessorBlockSyntax {

    /// Produces a description where all newlines and spaces are replaced by a single space
    ///
    /// e.g. "get\n set\n" -> "get set"
    var sanitizedDescription: String {
        accessors.trimmedDescription.sanitizingNewlinesAndSpaces
    }
}

extension String {

    /// Produces a string where all newlines and spaces are replaced by a single space
    ///
    /// e.g. "get\n set\n" -> "get set"
    var sanitizingNewlinesAndSpaces: String {
        self.replacingOccurrences(of: "[\n ]+", with: " ", options: .regularExpression)
    }
}
