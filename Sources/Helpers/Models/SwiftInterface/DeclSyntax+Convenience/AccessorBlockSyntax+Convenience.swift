import SwiftSyntax

extension AccessorBlockSyntax {
    var sanitizedDescription: String {
        accessors.trimmedDescription.replacingOccurrences(of: "[\n ]+", with: " ", options: .regularExpression)
    }
}
