//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

/// Gives explicit module-qualified types the legacy spelling used in older interfaces.
final class ModuleSelectorNormalizer: SyntaxRewriter {

    private let moduleName: String
    private let modules: Set<String>

    static func normalize(_ source: SourceFileSyntax, moduleName: String) -> Syntax {
        let names = ModuleNames(viewMode: .sourceAccurate)
        names.walk(source)
        guard names.hasTypeSelector else { return Syntax(source) }

        var modules = names.imports.union([moduleName])
        // SDK overlays can refer to modules imported transitively by the underlying framework.
        if names.reexportedModules.contains(moduleName) {
            modules.formUnion(names.selectorModules)
        }
        modules.subtract(names.declarations)
        return ModuleSelectorNormalizer(moduleName: moduleName, modules: modules).rewrite(source)
    }

    private init(moduleName: String, modules: Set<String>) {
        self.moduleName = moduleName
        self.modules = modules
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        let type = super.visit(node)
        guard let identifier = type.as(IdentifierTypeSyntax.self),
              let selector = identifier.moduleSelector,
              modules.contains(selector.moduleName.text) else {
            return type
        }

        return TypeSyntax(MemberTypeSyntax(
            baseType: IdentifierTypeSyntax(name: selector.moduleName.with(\.trailingTrivia, [])),
            name: identifier.name.with(\.leadingTrivia, []),
            genericArgumentClause: identifier.genericArgumentClause
        ))
    }

    override func visit(_ node: MemberTypeSyntax) -> TypeSyntax {
        let type = super.visit(node)
        guard var member = type.as(MemberTypeSyntax.self),
              !moduleName.isEmpty,
              member.moduleSelector?.moduleName.text == moduleName else {
            return type
        }

        // A selector on a nested type names the module that declared the member.
        // Older interfaces omit the selector on members declared in this module.
        member.moduleSelector = nil
        return TypeSyntax(member)
    }
}

private final class ModuleNames: SyntaxAnyVisitor {

    var imports: Set<String> = []
    var reexportedModules: Set<String> = []
    var selectorModules: Set<String> = []
    var declarations: Set<String> = []
    var hasTypeSelector = false

    override func visit(_ node: ModuleSelectorSyntax) -> SyntaxVisitorContinueKind {
        if node.parent?.is(IdentifierTypeSyntax.self) == true ||
            node.parent?.is(MemberTypeSyntax.self) == true {
            hasTypeSelector = true
            selectorModules.insert(node.moduleName.text)
        }
        return .skipChildren
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if let name = node.path.first?.name.text {
            imports.insert(name)
            if node.attributes.contains(where: {
                guard case let .attribute(attribute) = $0 else { return false }
                return attribute.attributeName.trimmedDescription == "_exported"
            }) {
                reexportedModules.insert(name)
            }
        }
        return .skipChildren
    }

    override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        // A local name can make legacy dot syntax refer to a type instead of a module.
        if let named = node.asProtocol(NamedDeclSyntax.self) {
            declarations.insert(named.name.text)
        }
        if let parameter = node.as(GenericParameterSyntax.self) {
            declarations.insert(parameter.name.text)
        }
        return .visitChildren
    }
}
