//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

// TODO: Add a protocol for this

struct SwiftInterfaceAnalyzer {
    
    let changeConsolidator: SwiftInterfaceChangeConsolidating
    
    init(
        changeConsolidator: SwiftInterfaceChangeConsolidating = SwiftInterfaceChangeConsolidator()
    ) {
        self.changeConsolidator = changeConsolidator
    }
    
    func analyze(
        old: some SwiftInterfaceElement,
        new: some SwiftInterfaceElement
    ) -> [Change] {
        
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
        
        if lhs.recursiveDescription() == rhs.recursiveDescription() { return [] }
        
        var changes = [IndependentSwiftInterfaceChange]()
        
        if !isRoot, oldFirst, lhs.description != rhs.description {
            changes += independentChanges(from: lhs, and: rhs, oldFirst: oldFirst)
        }
        
        changes += lhs.children.flatMap { lhsElement in

            // Trying to find a matching element
            
            // First checking if we found an exact match based on the description
            // as we don't want to match a non-change with a change
            if let exactMatch = rhs.children.first(where: { $0.description == lhsElement.description }) {
                // We found an exact match so we check if the children changed
                return Self.recursiveCompare(element: lhsElement, to: exactMatch, oldFirst: oldFirst)
            }
            
            // ... then losening the criteria to find a comparable element
            if let rhsChildForName = rhs.children.first(where: { $0.isDiffable(with: lhsElement) }) {
                // We found a comparable element so we check if the children changed
                return Self.recursiveCompare(element: lhsElement, to: rhsChildForName, oldFirst: oldFirst)
            }
    
            // No matching element was found so either it was removed or added
            let changeType: IndependentSwiftInterfaceChange.ChangeType = oldFirst ?
                .removal(lhsElement.description) :
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
}
