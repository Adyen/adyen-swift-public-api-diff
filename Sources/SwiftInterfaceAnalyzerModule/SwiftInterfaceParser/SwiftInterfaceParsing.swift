import Foundation

public protocol SwiftInterfaceParsing {
    func parse(source: String, moduleName: String) -> any SwiftInterfaceElement
}
