//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 02/10/2024.
//

import Foundation

fileprivate enum ChangeType {
    case change(old: String, new: String)
    case removal(String)
    case addition(String)
    
    var title: String {
        switch self {
        case .change: "Changed"
        case .removal: "Removed"
        case .addition: "Added"
        }
    }
    
    static func `for`(oldValue: String?, newValue: String?) -> Self? {
        if oldValue == newValue { return nil }
        if let oldValue, let newValue { return .change(old: oldValue, new: newValue) }
        if let oldValue { return .removal(oldValue) }
        if let newValue { return .addition(newValue) }
        return nil
    }
}

extension SwiftInterfaceElement {
    
    func diffDescription(propertyType: String?, oldValue: String?, newValue: String?) -> [String] {
        
        guard let changeType: ChangeType = .for(oldValue: oldValue, newValue: newValue) else { return [] }
        
        var diffDescription: String
        if let propertyType {
            diffDescription = "\(changeType.title) \(propertyType)"
        } else {
            diffDescription = "\(changeType.title)"
        }
        
        switch changeType {
        case .change(let old, let new):
            diffDescription += " from `\(old)` to `\(new)`"
        case .removal(let string):
            diffDescription += " `\(string)`"
        case .addition(let string):
            diffDescription += " `\(string)`"
        }
        
        return [diffDescription]
    }
    
    func diffDescription(propertyType: String, oldValues: [String]?, newValues: [String]?) -> [String] {
        
        if let oldValues, let newValues {
            let old = Set(oldValues)
            let new = Set(newValues)
            return old.symmetricDifference(new).map {
                "\(new.contains($0) ? "Added" : "Removed") \(propertyType) `\($0)`"
            }
        }
        
        if let oldValues {
            return oldValues.map { "Removed \(propertyType) `\($0)`" }
        }
        
        if let newValues {
            return newValues.map { "Added \(propertyType) `\($0)`" }
        }
        
        return []
    }
}
