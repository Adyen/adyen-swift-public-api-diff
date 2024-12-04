//
//  String+Convenience.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 04/12/2024.
//

import Foundation

internal extension String {
    
    /// Appends a string using a separator
    ///
    /// - Parameters:
    ///   - element: The string to append
    ///   - separator: The separator to use when appending the string
    ///   - template: The template to use to build the string (Helpful when the element is optional)
    ///
    /// - Important: The string is not added if it's nil or empty \
    /// If **self** is empty, the separator is ignored and **self** gets the value of the passed string
    mutating func append(
        _ element: String?,
        with separator: String,
        template: ((String) -> String) = { string in return string }
    ) {
        guard let element, !element.isEmpty else { return }
        
        let compiledElement = template(element)
        
        if self.isEmpty {
            self = compiledElement
            return
        }
        
        self = [self, compiledElement].joined(separator: separator)
    }
}
