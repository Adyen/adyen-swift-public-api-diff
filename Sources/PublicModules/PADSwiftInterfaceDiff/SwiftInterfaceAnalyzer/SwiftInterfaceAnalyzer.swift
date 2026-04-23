//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

struct SwiftInterfaceAnalyzer: SwiftInterfaceAnalyzing {

    let changeConsolidator: SwiftInterfaceChangeConsolidating

    init(changeConsolidator: SwiftInterfaceChangeConsolidating = SwiftInterfaceChangeConsolidator()) {
        self.changeConsolidator = changeConsolidator
    }

    func analyze(
        old: some SwiftInterfaceElement,
        new: some SwiftInterfaceElement
    ) -> [Change] {

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

    private static func recursiveCompare(
        element lhs: some SwiftInterfaceElement,
        to rhs: some SwiftInterfaceElement,
        oldFirst: Bool,
        isRoot: Bool = false
    ) -> [IndependentSwiftInterfaceChange] {

        var changes = [IndependentSwiftInterfaceChange]()

        if lhs.recursiveDescription() == rhs.recursiveDescription() { return changes }

        if !isRoot, oldFirst, lhs.description != rhs.description {
            changes += independentChanges(from: lhs, and: rhs, oldFirst: oldFirst)
        }

        changes += lhs.children.flatMap { lhsElement in

            // Trying to find a matching element

            // First checking if we found an exact match based on the recursive description
            // as we don't want to match a non-change with a change
            //
            // This is especially important for extensions where the description might
            // be the same for a lot of different extensions but the body might be completely different
            if rhs.children.first(where: { $0.recursiveDescription() == lhsElement.recursiveDescription() }) != nil {
                return [IndependentSwiftInterfaceChange]()
            }

            // First checking if we found a match based on the description
            // For extensions, we need special handling to find the best match based on child similarity
            if lhsElement is SwiftInterfaceExtension {
                let allDescriptionMatches = rhs.children.filter { $0.description == lhsElement.description }
                if let bestMatch = findBestExtensionMatch(for: lhsElement, among: allDescriptionMatches) {
                    return Self.recursiveCompare(element: lhsElement, to: bestMatch, oldFirst: oldFirst)
                }
                // No good match found, will fall through to isDiffable check or report as removal/addition
            } else if let descriptionMatch = rhs.children.first(where: { $0.description == lhsElement.description }) {
                // so we check if the children changed
                return Self.recursiveCompare(element: lhsElement, to: descriptionMatch, oldFirst: oldFirst)
            }

            // ... then losening the criteria to find a comparable element
            if let rhsChildForName = rhs.children.first(where: { $0.isDiffable(with: lhsElement) }) {
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
        among candidates: [any SwiftInterfaceElement]
    ) -> (any SwiftInterfaceElement)? {
        guard !candidates.isEmpty else { return nil }
        
        // If only one candidate, return it
        if candidates.count == 1 {
            return candidates.first
        }
        
        // Calculate similarity score for each candidate based on matching children
        let candidatesWithScores = candidates.map { candidate -> (element: any SwiftInterfaceElement, score: Int) in
            let matchingChildren = lhsElement.children.filter { lhsChild in
                candidate.children.contains { rhsChild in
                    // Check if children match by diffableSignature
                    rhsChild.diffableSignature == lhsChild.diffableSignature &&
                    type(of: rhsChild) == type(of: lhsChild)
                }
            }
            return (element: candidate, score: matchingChildren.count)
        }
        
        // Return the candidate with the highest score
        // If all scores are 0 (no matching children), return the first candidate as fallback
        return candidatesWithScores.max(by: { $0.score < $1.score })?.element
    }
}
