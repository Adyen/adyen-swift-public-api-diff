//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 08/10/2024.
//

import Foundation
import ArgumentParser

enum SwiftInterfaceType {
    case `private`
    case `public`
    
    var name: String {
        switch self {
        case .private: "private"
        case .public: "public"
        }
    }
}

extension SwiftInterfaceType: ExpressibleByArgument {
    init?(argument: String) {
        switch argument {
        case "private": self = .private
        case "public": self = .public
        default: return nil
        }
    }
}
