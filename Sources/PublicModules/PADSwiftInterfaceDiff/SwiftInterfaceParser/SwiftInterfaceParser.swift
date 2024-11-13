//
// Copyright (c) 2024 Adyen N.V.
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
    // - IfConfigClauseListSyntax
    // - ... (There are more but not important right now)
    
    private var scope: Scope = .root(elements: [])
    
    func parse(source: String, moduleName: String) -> any SwiftInterfaceElement {
        let visitor = Self()
        visitor.walk(Parser.parse(source: source))
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
        scope.start()
        return .visitChildren
    }
    
    /// Ends the current scope and adds the symbol returned by the closure to the symbol tree
    /// - Parameter makeSymbolWithChildrenInScope: Closure that return a new ``Symbol``
    ///
    /// Call in `visitPost(_ node:)` methods
    func endScopeAndAddSymbol(makeElementsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        scope.end(makeElementsWithChildrenInScope: makeElementsWithChildrenInScope)
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
    case nested(parent: Scope, elements: [any SwiftInterfaceElement])

    /// Starts a new nested scope
    mutating func start() {
        self = .nested(parent: self, elements: [])
    }

    /// Ends the current scope by adding new elements to the scope tree.
    /// The children provided in the closure are the symbols in the scope to be ended
    mutating func end(makeElementsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        let newElements = makeElementsWithChildrenInScope(elements)

        switch self {
        case .root:
            fatalError("Unbalanced calls to start() and end(_:)")

        case let .nested(.root(rootElements), _):
            self = .root(elements: rootElements + newElements)

        case let .nested(.nested(parent, parentElements), _):
            self = .nested(parent: parent, elements: parentElements + newElements)
        }
    }

    var elements: [any SwiftInterfaceElement] {
        switch self {
        case let .root(elements): return elements // All child elements recursive from the root
        case let .nested(_, elements): return elements // All child elements recursive from a nested element
        }
    }
}
