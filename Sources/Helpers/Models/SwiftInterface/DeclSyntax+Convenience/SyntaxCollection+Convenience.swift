import SwiftSyntax

extension SyntaxCollection {
    var sanitizedList: [String] {
        self.map { $0.trimmedDescription }
    }
}
