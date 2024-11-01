import SwiftSyntax

extension SyntaxCollection {
    
    /// Produces a description where all elements in the list are mapped to their `trimmedDescription`
    var sanitizedList: [String] {
        self.map { $0.trimmedDescription }
    }
}

extension AttributeListSyntax {
    
    private var excludedAttributes: Set<String> {
        [
            "@_hasMissingDesignatedInitializers",
            "@_inheritsConvenienceInitializers"
        ]
    }
    
    /// Produces a description where all elements in the list are mapped to their `trimmedDescription`
    var sanitizedList: [String] {
        self.compactMap {
            let description = $0.trimmedDescription
            if excludedAttributes.contains(description) { return nil }
            return description
        }
    }
}

extension InheritedTypeListSyntax {
    
    /// Produces a description where all elements in the list are mapped to their type's `trimmedDescription`
    var sanitizedList: [String] {
        self.map { $0.type.trimmedDescription }
    }
}

extension AccessorBlockSyntax {
    
    /// Produces a description where all newlines and spaces are replaced by a single space
    ///
    /// e.g. "get\n set\n" -> "get set"
    var sanitizedDescription: String {
        accessors.trimmedDescription.sanitizingNewlinesAndSpaces
    }
}

extension String {
    
    /// Produces a string where all newlines and spaces are replaced by a single space
    ///
    /// e.g. "get\n set\n" -> "get set"
    var sanitizingNewlinesAndSpaces: String {
        self.replacingOccurrences(of: "[\n ]+", with: " ", options: .regularExpression)
    }
}
