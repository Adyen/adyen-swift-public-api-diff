//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// A change indicating an `addition`, `removal` or genuine `change` of an element
public struct Change: Equatable {
    public enum ChangeType: Equatable {
        case addition(description: String)
        case removal(description: String)
        case modification(oldDescription: String, newDescription: String)
    }

    public private(set) var changeType: ChangeType
    public private(set) var parentPath: String?

    public private(set) var listOfChanges: [String] = []

    /// The conditions of the `#if` clauses the changed element is declared in (including the ones
    /// of its enclosing declarations), outermost first. Empty if the element is declared unconditionally.
    ///
    /// e.g. `["compiler(>=5.3) && $TildeSendable"]` or `["!$Embedded"]`
    public private(set) var conditions: [String] = []

    public init(
        changeType: ChangeType,
        parentPath: String? = nil,
        listOfChanges: [String] = [],
        conditions: [String] = []
    ) {
        self.changeType = changeType
        self.parentPath = parentPath
        self.listOfChanges = listOfChanges.sorted()
        self.conditions = conditions
    }
}

extension Change.ChangeType {

    public var isAddition: Bool {
        switch self {
        case .addition:
            return true
        case .removal:
            return false
        case .modification:
            return false
        }
    }

    public var isRemoval: Bool {
        switch self {
        case .addition:
            return false
        case .removal:
            return true
        case .modification:
            return false
        }
    }

    public var isModification: Bool {
        switch self {
        case .addition:
            return false
        case .removal:
            return false
        case .modification:
            return true
        }
    }
}
