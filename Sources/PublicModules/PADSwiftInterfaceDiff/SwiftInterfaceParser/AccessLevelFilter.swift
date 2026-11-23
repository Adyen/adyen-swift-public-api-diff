//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

/// Removes declarations that are outside of the ``APIScope`` from a parsed interface.
///
/// Only an explicit access modifier hides a declaration:
/// - Declarations without an access modifier keep the access of their parent
///   (enum cases, protocol requirements, members of extensions) or stay as they are.
/// - `public private(set) var` stays, as only the setter is restricted.
/// - `@usableFromInline` declarations stay, as they are ABI relevant.
/// - Members of a removed declaration are removed with it.
/// - An extension whose members are all removed is removed as well, unless it adds a conformance.
final class AccessLevelFilter: SyntaxRewriter {

    private let apiScope: APIScope

    static func filter(_ source: SourceFileSyntax, apiScope: APIScope) -> SourceFileSyntax {
        guard apiScope != .all else { return source }
        return AccessLevelFilter(apiScope: apiScope).rewrite(source).cast(SourceFileSyntax.self)
    }

    private init(apiScope: APIScope) {
        self.apiScope = apiScope
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        // Only the top level (including `#if` blocks) is filtered here, bodies of functions are left untouched
        guard node.parent?.is(SourceFileSyntax.self) == true || node.parent?.is(IfConfigClauseSyntax.self) == true else {
            return super.visit(node)
        }
        let filtered = CodeBlockItemListSyntax(node.filter { item in
            guard case let .decl(decl) = item.item else { return true }
            return !decl.isHidden(outside: apiScope)
        })
        return super.visit(filtered)
    }

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let filtered = MemberBlockItemListSyntax(node.filter { !$0.decl.isHidden(outside: apiScope) })
        return super.visit(filtered)
    }
}

private extension DeclSyntax {

    /// `true` if the declaration has an explicit access modifier outside of the API scope
    func isHidden(outside apiScope: APIScope) -> Bool {
        // An extension that only contained hidden members would otherwise remain as an empty extension
        // (e.g. `extension Foundation.Data {}`) and be reported as an addition.
        // Extensions that add a conformance are kept as the conformance is part of the API.
        if let extensionDecl = self.as(ExtensionDeclSyntax.self),
           extensionDecl.inheritanceClause == nil,
           !extensionDecl.memberBlock.members.isEmpty,
           extensionDecl.memberBlock.members.allSatisfy({ $0.decl.isHidden(outside: apiScope) }) {
            return true
        }

        guard let modifiable = asProtocol((any WithModifiersSyntax).self) else { return false }

        let hasHidingModifier = modifiable.modifiers.contains { modifier in
            // `private(set)` has a detail and only restricts the setter
            guard modifier.detail == nil else { return false }
            switch modifier.name.tokenKind {
            case .keyword(.private), .keyword(.fileprivate), .keyword(.internal):
                return apiScope != .all
            case .keyword(.package):
                return apiScope == .public
            default:
                return false
            }
        }
        guard hasHidingModifier else { return false }

        // `@usableFromInline` declarations are part of the ABI of the module
        if let attributed = asProtocol((any WithAttributesSyntax).self) {
            let isUsableFromInline = attributed.attributes.contains { element in
                guard case let .attribute(attribute) = element else { return false }
                return attribute.attributeName.trimmedDescription == "usableFromInline"
            }
            if isUsableFromInline { return false }
        }
        return true
    }
}
