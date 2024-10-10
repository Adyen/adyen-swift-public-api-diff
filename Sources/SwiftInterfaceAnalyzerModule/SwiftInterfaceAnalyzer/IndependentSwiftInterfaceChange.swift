import Foundation
import CoreModule

/// A change indicating an `addition` or `removal` of an element
///
/// This intermediate structure helps gathering a list of additions and removals
/// that are later consolidated to a ``Change``
public struct IndependentSwiftInterfaceChange: Equatable {
    
    enum ChangeType: Equatable {
        case addition(_ description: String)
        case removal(_ description: String)

        var description: String {
            switch self {
            case let .addition(description): description
            case let .removal(description): description
            }
        }
    }

    let changeType: ChangeType
    let element: any SwiftInterfaceElement

    let oldFirst: Bool
    var parentPath: String? { element.parentPath }
    
    public static func == (lhs: IndependentSwiftInterfaceChange, rhs: IndependentSwiftInterfaceChange) -> Bool {
        lhs.changeType == rhs.changeType &&
        lhs.element.description == rhs.element.description &&
        lhs.oldFirst == rhs.oldFirst &&
        lhs.parentPath == rhs.parentPath
    }
    
    func differences(to otherIndependentChange: IndependentSwiftInterfaceChange) -> [String] {
        element.differences(to: otherIndependentChange.element).sorted()
    }
}
