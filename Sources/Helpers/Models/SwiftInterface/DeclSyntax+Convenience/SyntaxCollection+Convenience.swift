import SwiftSyntax

extension SyntaxCollection {
    var sanitizedList: [String] {
        self.map { $0.trimmedDescription }
    }
}

extension InheritedTypeListSyntax {
    var sanitizedList: [String] {
        self.map { $0.type.trimmedDescription }
    }
}
