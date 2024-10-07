//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 07/10/2024.
//

import Foundation

extension SwiftInterfaceParser {
    
    class Root: SwiftInterfaceElement {
        
        var parent: (any SwiftInterfaceElement)? = nil
        
        var diffableSignature: String { "" }
        
        var consolidatableName: String { "" }
        
        var description: String {
            var description = ""
            children.forEach { child in
                description.append(child.recursiveDescription())
                description.append("\n")
            }
            return description
        }
        
        var childGroupName: String { moduleName }
        
        private let moduleName: String
        private(set) var children: [any SwiftInterfaceElement]
        
        init(moduleName: String, elements: [any SwiftInterfaceElement]) {
            self.moduleName = moduleName
            self.children = elements
            
            self.children = Self.mergeExtensions(for: self.children, moduleName: moduleName)
            self.children.forEach { $0.setupParentRelationships(parent: self) }
        }
        
        func differences<T: SwiftInterfaceElement>(to otherElement: T) -> [String] {
            return []
        }
        
        /// Attempting to merge extensions into their extended type to allow for better diffing
        /// Independent extensions (without a where clause) are very hard to diff as the only information we have
        /// is the extended type and there might be a lot of changes inside of the extensions between versions
        static func mergeExtensions(for elements: [any SwiftInterfaceElement], moduleName: String) -> [any SwiftInterfaceElement] {
            let extensions = elements.compactMap { $0 as? (SwiftInterfaceExtension & SwiftInterfaceElement) }
            let extendableElements = elements.compactMap { $0 as? (SwiftInterfaceExtendableElement & SwiftInterfaceElement) }
            let nonExtensions = elements.filter { !($0 is SwiftInterfaceExtension) }
            
            var adjustedElements: [any SwiftInterfaceElement] = nonExtensions
            
            extensions.forEach { extensionElement in
                
                // We want to merge all extensions that don't have a where clause into the extended type
                guard extensionElement.genericWhereClauseDescription == nil else {
                    adjustedElements.append(extensionElement)
                    return
                }
                
                if merge(extensionElement: extensionElement, with: extendableElements, prefix: moduleName) {
                    return // We found the matching extended element
                }
                
                // We could not find the extended type so we add the extension to the list
                adjustedElements.append(extensionElement)
            }
            
            return adjustedElements
        }
        
        /// Attempting to recursively merge an extension element with potential matches of extendable elements
        /// The prefix provides the parent path as the types don't include it but the `extension.extendedType` does
        static func merge(
            extensionElement: any (SwiftInterfaceExtension & SwiftInterfaceElement),
            with extendableElements: [any (SwiftInterfaceExtendableElement & SwiftInterfaceElement)],
            prefix: String
        ) -> Bool {
            
            if let extendedElement = extendableElements.first(where: { extensionElement.extendedType.hasPrefix("\(prefix).\($0.typeName)") }) {
                
                let extendedElementPrefix = "\(prefix).\(extendedElement.typeName)"
                
                // We found the extended type
                if extendedElementPrefix == extensionElement.extendedType {
                    extendedElement.inheritance = (extendedElement.inheritance ?? []) + (extensionElement.inheritance ?? [])
                    extendedElement.children += extensionElement.children
                    return true
                }
                
                // We're looking for the extended type inside of the children
                let extendableChildren = extendedElement.children.compactMap { $0 as? (SwiftInterfaceExtendableElement & SwiftInterfaceElement) }
                return merge(extensionElement: extensionElement, with: extendableChildren, prefix: extendedElementPrefix)
            }
            
            return false
        }
    }
}
