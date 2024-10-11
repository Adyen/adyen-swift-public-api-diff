import Foundation
import PADCore

protocol SwiftInterfaceAnalyzing {
    func analyze(old: some SwiftInterfaceElement, new: some SwiftInterfaceElement) throws -> [PADChange]
}
