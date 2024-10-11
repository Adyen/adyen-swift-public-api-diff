//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADCore

public struct SwiftInterfaceAnalyzer: SwiftInterfaceAnalyzing {
    
    let changeConsolidator: SwiftInterfaceChangeConsolidating
    
    public init() {
        self.init(changeConsolidator: SwiftInterfaceChangeConsolidator())
    }
    
    init(changeConsolidator: SwiftInterfaceChangeConsolidating) {
        self.changeConsolidator = changeConsolidator
    }
    
    public func analyze(
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
            if let descriptionMatch = rhs.children.first(where: { $0.description == lhsElement.description }) {
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
