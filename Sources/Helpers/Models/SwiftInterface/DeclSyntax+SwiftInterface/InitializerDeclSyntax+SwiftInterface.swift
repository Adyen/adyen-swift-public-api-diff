import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/initializerdeclsyntax
extension InitializerDeclSyntax {
    
    func toInterfaceElement() -> SwiftInterfaceInitializer {
        
        var effectSpecifiers = [String]()
        
        if let effects = signature.effectSpecifiers {
            if let asyncSpecifier = effects.asyncSpecifier {
                effectSpecifiers.append(asyncSpecifier.trimmedDescription)
            }
            if let throwsClause = effects.throwsClause {
                effectSpecifiers.append(throwsClause.trimmedDescription)
            }
        }
        
        let parameters: [SwiftInterfaceInitializer.Parameter] = self.signature.parameterClause.parameters.map {
            .init(
                firstName: $0.firstName.trimmedDescription,
                secondName: $0.secondName?.trimmedDescription,
                type: $0.type.trimmedDescription,
                defaultValue: $0.defaultValue?.value.description
            )
        }
        
        return SwiftInterfaceInitializer(
            attributes: self.attributes.sanitizedList,
            modifiers: self.modifiers.sanitizedList,
            optionalMark: optionalMark?.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            parameters: parameters,
            effectSpecifiers: effectSpecifiers,
            returnType: signature.returnClause?.type.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
