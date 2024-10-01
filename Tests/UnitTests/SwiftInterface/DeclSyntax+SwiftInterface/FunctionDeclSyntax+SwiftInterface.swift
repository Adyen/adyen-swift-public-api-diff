import SwiftSyntax
import SwiftParser

/// See: https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/functiondeclsyntax
extension FunctionDeclSyntax {
    
    func toInterfaceElement() -> SwiftInterfaceFunction {
        
        var effectSpecifiers = [String]()
        
        if let effects = signature.effectSpecifiers {
            if let asyncSpecifier = effects.asyncSpecifier {
                effectSpecifiers.append(asyncSpecifier.trimmedDescription)
            }
            if let throwsClause = effects.throwsClause {
                effectSpecifiers.append(throwsClause.trimmedDescription)
            }
        }
        
        let parameters: [SwiftInterfaceFunction.Parameter] = self.signature.parameterClause.parameters.map {
            .init(
                firstName: $0.firstName.trimmedDescription,
                secondName: $0.secondName?.trimmedDescription,
                type: $0.type.trimmedDescription,
                defaultValue: $0.defaultValue?.trimmedDescription
            )
        }
        
        return SwiftInterfaceFunction(
            declarationAttributes: self.attributes.map { $0.trimmedDescription },
            modifiers: self.modifiers.map { $0.trimmedDescription },
            name: self.name.trimmedDescription,
            genericParameterDescription: self.genericParameterClause?.trimmedDescription,
            parameters: parameters,
            effectSpecifiers: effectSpecifiers,
            returnType: signature.returnClause?.type.trimmedDescription,
            genericWhereClauseDescription: self.genericWhereClause?.trimmedDescription
        )
    }
}
