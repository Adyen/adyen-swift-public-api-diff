//
//  SwiftInterfaceElement+Parameters.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 04/12/2024.
//

import Foundation

extension SwiftInterfaceElement {
    func formattedParameterDescription(for parameterDescriptions: [String]) -> String {
        // We're only doing multiline formatting if we have more than 1 character
        guard parameterDescriptions.count > 1 else { return parameterDescriptions.joined(separator: ", ") }
        
        let spacer = "  "
        var description = "\n\(spacer)"
        description.append(parameterDescriptions.joined(separator: ",\n\(spacer)"))
        description.append("\n")
        return description
    }
}
