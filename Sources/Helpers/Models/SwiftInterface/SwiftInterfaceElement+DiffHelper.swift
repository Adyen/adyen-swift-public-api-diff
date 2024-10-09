import Foundation

extension SwiftInterfaceElement {
    
    /// Returns a description for a change between an old and new value
    /// - Parameters:
    ///   - propertyType: The (optional) property type name (e.g. "accessor", "modifier", "generic where clause", ...) for additional information
    ///   - oldValue: The (optional) old value
    ///   - newValue: The (optional) new value
    /// - Returns: A list with a single item that represents a change description caused by a value change
    func diffDescription(
        propertyType: String?,
        oldValue: String?,
        newValue: String?
    ) -> [String] {
        
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
    
    /// Returns a list of change descriptions for changes between the old and new values
    /// - Parameters:
    ///   - propertyType: The (optional) property type name (e.g. "accessor", "modifier", "generic where clause", ...) for additional information
    ///   - oldValue: The (optional) old values
    ///   - newValue: The (optional) new values
    /// - Returns: A list of change descriptions caused by a value change
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

// MARK: -

/// File-private helper to produce detailed descriptions
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
