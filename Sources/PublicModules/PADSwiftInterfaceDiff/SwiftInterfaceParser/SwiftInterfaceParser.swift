//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import SwiftParser
import SwiftSyntax

/// Parses the source content of a swift file into intermediate objects for further processing
///
/// See:
/// - [DeclSyntax](https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/declsyntax)
class SwiftInterfaceParser: SyntaxVisitor, SwiftInterfaceParsing {

    // TODO: Handle (Nice to have)
    // - DeinitializerDeclSyntax
    // - PrecedenceGroupDeclSyntax
    // - OperatorDeclSyntax
    // - ... (There are more but not important right now)

    private var scope: Scope = .root(elements: [])

    /// The conditions of the `#if` clauses that are currently visited, outermost first
    private var conditionStack = [String]()

    func parse(source: String, moduleName: String) -> any SwiftInterfaceElement {
        let visitor = Self()
        let syntax = Parser.parse(source: source)
        visitor.walk(ModuleSelectorNormalizer.normalize(syntax, moduleName: moduleName))
        return Root(
            moduleName: moduleName,
            elements: visitor.scope.elements
        )
    }

    /// Designated initializer
    required init() {
        super.init(viewMode: .sourceAccurate)
    }

    /// Starts a new scope which can contain zero or more nested symbols
    func startScope() -> SyntaxVisitorContinueKind {
        // The conditions of `#if` clauses entered since the enclosing scope started apply to the new element
        scope.start(
            conditions: Array(conditionStack.dropFirst(scope.conditionDepth)),
            conditionDepth: conditionStack.count
        )
        return .visitChildren
    }

    /// Ends the current scope and adds the symbol returned by the closure to the symbol tree
    /// - Parameter makeSymbolWithChildrenInScope: Closure that return a new ``Symbol``
    ///
    /// Call in `visitPost(_ node:)` methods
    func endScopeAndAddSymbol(makeElementsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        scope.end(makeElementsWithChildrenInScope: makeElementsWithChildrenInScope)
    }

    // MARK: - Conditional compilation

    /// Visits every clause of an `#if`, tagging the declarations with the clause's condition
    /// (see ``ConditionalCompilation``)
    override open func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        for (clause, condition) in ConditionalCompilation.clauses(of: node) {
            guard let elements = clause.elements else { continue }
            conditionStack.append(condition)
            walk(elements)
            conditionStack.removeLast()
        }
        return .skipChildren
    }

    // MARK: - Class

    override open func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: ClassDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - Struct

    override open func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: StructDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - TypeAlias

    override open func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: TypeAliasDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - Function

    override open func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: FunctionDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }

    // MARK: - Var

    override open func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: VariableDeclSyntax) {
        endScopeAndAddSymbol { _ in node.toInterfaceElement() }
    }

    // MARK: - AssociatedType

    override open func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: AssociatedTypeDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }

    // MARK: - Protocol

    override open func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: ProtocolDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - Enum

    override open func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: EnumDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - EnumCase

    override open func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: EnumCaseDeclSyntax) {
        endScopeAndAddSymbol { node.toInterfaceElement(children: $0) }
    }

    // MARK: - Extension

    override open func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: ExtensionDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - Initializer

    override open func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: InitializerDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }

    // MARK: - Actor

    override open func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: ActorDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }

    // MARK: - Macro

    override open func visit(_ node: MacroDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: MacroDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }

    // MARK: - Subscript

    override open func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    override open func visitPost(_ node: SubscriptDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }
}

// MARK: - Scope

private indirect enum Scope {

    /// The root scope of a file
    case root(elements: [any SwiftInterfaceElement])

    /// A nested scope, within a parent scope
    ///
    /// - `conditions`: The conditions of the `#if` clauses the element of the scope is declared in
    /// - `conditionDepth`: The number of `#if` clauses entered when the scope started
    case nested(parent: Scope, elements: [any SwiftInterfaceElement], conditions: [String], conditionDepth: Int)

    /// Starts a new nested scope
    mutating func start(conditions: [String], conditionDepth: Int) {
        self = .nested(parent: self, elements: [], conditions: conditions, conditionDepth: conditionDepth)
    }

    /// Ends the current scope by adding new elements to the scope tree.
    /// The children provided in the closure are the symbols in the scope to be ended
    mutating func end(makeElementsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        let newElements = makeElementsWithChildrenInScope(elements)

        guard case let .nested(parent, _, conditions, _) = self else {
            fatalError("Unbalanced calls to start() and end(_:)")
        }

        if !conditions.isEmpty {
            newElements.compactMap { $0 as? SwiftInterfaceAttributedElement }.forEach {
                $0.attributes = ConditionalCompilation.attributes($0.attributes, adding: conditions)
            }
        }

        switch parent {
        case let .root(rootElements):
            self = .root(elements: rootElements + newElements)

        case let .nested(grandParent, parentElements, parentConditions, parentConditionDepth):
            self = .nested(
                parent: grandParent,
                elements: parentElements + newElements,
                conditions: parentConditions,
                conditionDepth: parentConditionDepth
            )
        }
    }

    var elements: [any SwiftInterfaceElement] {
        switch self {
        case let .root(elements): return elements // All child elements recursive from the root
        case let .nested(_, elements, _, _): return elements // All child elements recursive from a nested element
        }
    }

    /// The number of `#if` clauses entered when the scope started
    var conditionDepth: Int {
        switch self {
        case .root: return 0
        case let .nested(_, _, _, conditionDepth): return conditionDepth
        }
    }
}
