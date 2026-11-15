//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

struct SwiftInterfaceAnalyzer: SwiftInterfaceAnalyzing {

    private static let comparisonTokens: Set<SwiftInterfaceElementDescriptionToken> = [.attributes, .modifiers]

    let changeConsolidator: SwiftInterfaceChangeConsolidating

    init(changeConsolidator: SwiftInterfaceChangeConsolidating = SwiftInterfaceChangeConsolidator()) {
        self.changeConsolidator = changeConsolidator
    }

    func analyze(
        old: some SwiftInterfaceElement,
        new: some SwiftInterfaceElement
    ) -> [Change] {

        RecursiveDescriptionCache.withCache {
            // Very naive diff from both sides
            // There is room for improvement here but it's "performant enough" for now

            let individualChanges = Self.recursiveCompare(
                element: old,
                to: new,
                oldFirst: true,
                isRoot: true
            ) + Self.recursiveCompare(
                element: new,
                to: old,
                oldFirst: false,
                isRoot: true
            )

            // Matching removals/additions to changes when applicable
            return changeConsolidator.consolidate(individualChanges)
        }
    }

    private static func recursiveCompare(
        element lhs: some SwiftInterfaceElement,
        to rhs: some SwiftInterfaceElement,
        oldFirst: Bool,
        isRoot: Bool = false
    ) -> [IndependentSwiftInterfaceChange] {

        var changes = [IndependentSwiftInterfaceChange]()

        if lhs.recursiveDescription(incl: comparisonTokens) == rhs.recursiveDescription(incl: comparisonTokens) { return changes }

        if !isRoot, oldFirst, lhs.description(incl: comparisonTokens) != rhs.description(incl: comparisonTokens) {
            changes += independentChanges(from: lhs, and: rhs, oldFirst: oldFirst)
        }

        let exactMatches = Set(rhs.children.map { $0.recursiveDescription(incl: comparisonTokens) })
        // Elements of `rhs` that are an exact counterpart of an element of `lhs` are accounted for
        // and must not be paired with another element as well
        let exactCounterparts = Set(lhs.children.map { $0.recursiveDescription(incl: comparisonTokens) })
        changes += lhs.children.flatMap { lhsElement in

            // Trying to find a matching element

            // First checking if we found an exact match based on the recursive description
            // as we don't want to match a non-change with a change
            //
            // This is especially important for extensions where the description might
            // be the same for a lot of different extensions but the body might be completely different
            if exactMatches.contains(lhsElement.recursiveDescription(incl: comparisonTokens)) {
                return [IndependentSwiftInterfaceChange]()
            }

            // First checking if we found a match based on the description
            // For extensions, we need special handling to find the best match based on child similarity
            if lhsElement is SwiftInterfaceExtension {
                let allDescriptionMatches = rhs.children.filter { $0.description(incl: comparisonTokens) == lhsElement.description(incl: comparisonTokens) }
                if let bestMatch = findBestExtensionMatch(for: lhsElement, among: allDescriptionMatches, excluding: exactCounterparts) {
                    return Self.recursiveCompare(element: lhsElement, to: bestMatch, oldFirst: oldFirst)
                }
                // No good match found, will fall through to isDiffable check or report as removal/addition
            } else if let descriptionMatch = rhs.children.first(where: { $0.description(incl: comparisonTokens) == lhsElement.description(incl: comparisonTokens) }) {
                // so we check if the children changed
                return Self.recursiveCompare(element: lhsElement, to: descriptionMatch, oldFirst: oldFirst)
            }

            // ... then losening the criteria to find a comparable element
            // Extensions of the same type are all comparable, so pick the one declaring the same
            // conformances / members instead of the first (e.g. after an availability change)
            if lhsElement is SwiftInterfaceExtension {
                let comparableExtensions = rhs.children.filter { $0.isDiffable(with: lhsElement) }
                if let bestMatch = findBestExtensionMatch(for: lhsElement, among: comparableExtensions, excluding: exactCounterparts) {
                    return Self.recursiveCompare(element: lhsElement, to: bestMatch, oldFirst: oldFirst)
                }
            } else if let rhsChildForName = rhs.children.first(where: { $0.isDiffable(with: lhsElement) }) {
                // We found a comparable element so we check if the children changed
                return Self.recursiveCompare(element: lhsElement, to: rhsChildForName, oldFirst: oldFirst)
            }

            // No matching element was found so either it was removed or added
            let changeType: IndependentSwiftInterfaceChange.ChangeType = oldFirst ?
                .removal(lhsElement.recursiveDescription()) :
                .addition(lhsElement.recursiveDescription())

            return [
                .from(
                    changeType: changeType,
                    element: lhsElement,
                    oldFirst: oldFirst
                )
            ]
        }

        return changes
    }

    private static func independentChanges(
        from lhs: any SwiftInterfaceElement,
        and rhs: any SwiftInterfaceElement,
        oldFirst: Bool
    ) -> [IndependentSwiftInterfaceChange] {
        [
            .from(
                changeType: .removal(lhs.description),
                element: lhs,
                oldFirst: oldFirst
            ),
            .from(
                changeType: .addition(rhs.recursiveDescription()),
                element: rhs,
                oldFirst: oldFirst
            )
        ]
    }
    
    /// Finds the best matching extension from a list of candidates based on child similarity
    /// Returns nil if no good match is found
    private static func findBestExtensionMatch(
        for lhsElement: any SwiftInterfaceElement,
        among candidates: [any SwiftInterfaceElement],
        excluding exactCounterparts: Set<String>
    ) -> (any SwiftInterfaceElement)? {
        let candidates = candidates.filter { !exactCounterparts.contains($0.recursiveDescription(incl: comparisonTokens)) }
        guard !candidates.isEmpty else { return nil }
        
        // If only one candidate, return it
        if candidates.count == 1 {
            return candidates.first
        }
        
        // Calculate similarity scores for each candidate:
        // same conformances first, then shared conformances, then matching children
        let lhsConformances = Set((lhsElement as? SwiftInterfaceExtension)?.inheritance ?? [])
        let candidatesWithScores = candidates.map { candidate -> (element: any SwiftInterfaceElement, score: [Int]) in
            let candidateConformances = Set((candidate as? SwiftInterfaceExtension)?.inheritance ?? [])
            let matchingChildren = lhsElement.children.filter { lhsChild in
                candidate.children.contains { rhsChild in
                    // Check if children match by diffableSignature
                    rhsChild.diffableSignature == lhsChild.diffableSignature &&
                    type(of: rhsChild) == type(of: lhsChild)
                }
            }
            return (element: candidate, score: [
                lhsConformances == candidateConformances ? 1 : 0,
                lhsConformances.intersection(candidateConformances).count,
                matchingChildren.count
            ])
        }

        // Return the candidate with the highest score
        // If all scores are equal, return the first candidate as fallback
        return candidatesWithScores.max(by: { $0.score.lexicographicallyPrecedes($1.score) })?.element
    }
}
