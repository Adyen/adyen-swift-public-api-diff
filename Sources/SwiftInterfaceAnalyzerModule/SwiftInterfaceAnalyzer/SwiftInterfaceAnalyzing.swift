import Foundation
import CoreModule

public protocol SwiftInterfaceAnalyzing {
    func analyze(old: some SwiftInterfaceElement, new: some SwiftInterfaceElement) throws -> [Change]
}
