import Foundation

/// A change indicating an `addition` or `removal` of an element
///
/// This intermediate structure helps gathering a list of additions and removals
/// that are later consolidated to a ``Change``
struct IndependentSDKDumpChange: Equatable {
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
    let element: SDKDump.Element

    let oldFirst: Bool
    var parentPath: String { element.parentPath }
}
