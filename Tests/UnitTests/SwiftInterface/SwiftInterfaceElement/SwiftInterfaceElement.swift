@testable import public_api_diff
import Foundation

protocol SwiftInterfaceElement: CustomStringConvertible {
    var type: SDKDump.DeclarationKind { get }
    var description: String { get }
    var children: [any SwiftInterfaceElement] { get }
}

extension SwiftInterfaceElement {
    func recursiveDescription(indentation: Int = 0) -> String {
        let spacer = "  "
        var recursiveDescription = "\(String(repeating: spacer, count: indentation))\(description)"
        if !self.children.isEmpty {
            recursiveDescription.append("\n\(String(repeating: spacer, count: indentation)){")
            for child in self.children {
                recursiveDescription.append("\n\(String(repeating: spacer, count: indentation))\(child.recursiveDescription(indentation: indentation + 1))")
            }
            recursiveDescription.append("\n\(String(repeating: spacer, count: indentation))}")
        }
        return recursiveDescription
    }
}

extension SwiftInterfaceElement {
    var isSpiInternal: Bool {
        description.range(of: "@_spi(") != nil
    }
}

struct Placeholder: SwiftInterfaceElement {
    let type: SDKDump.DeclarationKind
    let children: [any SwiftInterfaceElement]
    
    var description: String {
        return "\(type) Placeholder"
    }
    
    init(type: SDKDump.DeclarationKind, children: [any SwiftInterfaceElement] = []) {
        self.type = type
        self.children = children
    }
}
