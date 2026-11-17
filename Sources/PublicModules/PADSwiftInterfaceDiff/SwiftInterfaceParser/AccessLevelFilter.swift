//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import SwiftSyntax

/// Removes declarations that are not part of the source-level API from a parsed interface.
///
/// Interfaces generated without library evolution (`BUILD_LIBRARY_FOR_DISTRIBUTION = NO`) still contain
/// `private`, `fileprivate` and `internal` declarations (e.g. stored properties).
/// Interfaces generated with library evolution only contain them when they are ABI relevant.
///
/// Only an explicit access modifier hides a declaration:
/// - Declarations without an access modifier keep the access of their parent
///   (enum cases, protocol requirements, members of extensions) or stay as they are.
/// - `public private(set) var` stays, as only the setter is restricted.
/// - `@usableFromInline internal` declarations stay, as they are ABI relevant.
/// - Members of a removed declaration are removed with it.
final class AccessLevelFilter: SyntaxRewriter {

    static func filter(_ source: SourceFileSyntax) -> SourceFileSyntax {
        AccessLevelFilter(viewMode: .sourceAccurate).rewrite(source).cast(SourceFileSyntax.self)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        // Only the top level is filtered here, bodies of functions are left untouched
        guard node.parent?.is(SourceFileSyntax.self) == true else {
            return super.visit(node)
        }
        let filtered = CodeBlockItemListSyntax(node.filter { item in
            guard case let .decl(decl) = item.item else { return true }
            return !decl.isHiddenFromAPI
        })
        return super.visit(filtered)
    }

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let filtered = MemberBlockItemListSyntax(node.filter { !$0.decl.isHiddenFromAPI })
        return super.visit(filtered)
    }
}

private extension DeclSyntax {

    /// `true` if the declaration has an explicit `private`, `fileprivate` or `internal` modifier
    var isHiddenFromAPI: Bool {
        guard let modifiable = asProtocol((any WithModifiersSyntax).self) else { return false }

        let hasHidingModifier = modifiable.modifiers.contains { modifier in
            // `private(set)` has a detail and only restricts the setter
            guard modifier.detail == nil else { return false }
            switch modifier.name.tokenKind {
            case .keyword(.private), .keyword(.fileprivate), .keyword(.internal): return true
            default: return false
            }
        }
        guard hasHidingModifier else { return false }

        // `@usableFromInline internal` is part of the ABI of the module
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
