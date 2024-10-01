@testable import public_api_diff
import Foundation
import SwiftSyntax
import SwiftParser

/**
 Inspired by: https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
 Documentation about DeclSyntax:
 - https://swiftpackageindex.com/swiftlang/swift-syntax/600.0.1/documentation/swiftsyntax/declsyntax
 */
class SwiftInterfaceParser: SyntaxVisitor {
    
    private var scope: Scope = .root(symbols: [])
    
    static public func parse(source: String) -> [any SwiftInterfaceElement] {
        let visitor = Self()
        visitor.walk(Parser.parse(source: source))
        return visitor.scope.symbols
    }
    
    /// Designated initializer
    required public init() {
        super.init(viewMode: .sourceAccurate)
    }
    
    /// Starts a new scope which can contain zero or more nested symbols
    public func startScope() -> SyntaxVisitorContinueKind {
        scope.start()
        return .visitChildren
    }
    
    /// Ends the current scope and adds the symbol returned by the closure to the symbol tree
    /// - Parameter makeSymbolWithChildrenInScope: Closure that return a new ``Symbol``
    ///
    /// Call in `visitPost(_ node:)` methods
    public func endScopeAndAddSymbol(makeSymbolsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        scope.end(makeSymbolsWithChildrenInScope: makeSymbolsWithChildrenInScope)
    }
    
    // TODO:
    // - InitializerDeclSyntax
    // - DeinitializerDeclSyntax
    // - ActorDeclSyntax
    // - AccessorDeclSyntax
    // - ExtensionDeclSyntax
    //
    // Nice to have:
    // - PrecedenceGroupDeclSyntax
    // - OperatorDeclSyntax
    // - SubscriptDeclSyntax
    // - IfConfigClauseListSyntax
    // - ... (There are more but not important right now)
    
    // MARK: - Class
    
    open override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    open override func visitPost(_ node: ClassDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - Struct
    
    open override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    open override func visitPost(_ node: StructDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - TypeAlias
    
    open override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: TypeAliasDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - Function
    
    open override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: FunctionDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }
    
    // MARK: - Var
    
    open override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    open override func visitPost(_ node: VariableDeclSyntax) {
        endScopeAndAddSymbol { _ in node.toInterfaceElement() }
    }
    
    // MARK: - AssociatedType
    
    open override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: AssociatedTypeDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }
    
    // MARK: - Protocol
    
    open override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: ProtocolDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - Enum
    
    open override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: EnumDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - EnumCase
    
    open override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: EnumCaseDeclSyntax) {
        endScopeAndAddSymbol { node.toInterfaceElement(children: $0) }
    }
}

// MARK: - Models

/// Inspired by: https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
indirect enum Scope {

    /// The root scope of a file
    case root(symbols: [any SwiftInterfaceElement])
    /// A nested scope, within a parent scope
    case nested(parent: Scope, symbols: [any SwiftInterfaceElement])

    /// Starts a new nested scope
    mutating func start() {
        self = .nested(parent: self, symbols: [])
    }

    /// Ends the current scope by adding a new symbol to the scope tree.
    /// The children provided in the closure are the symbols in the scope to be ended
    mutating func end(makeSymbolsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        let newSymbols = makeSymbolsWithChildrenInScope(symbols)

        switch self {
        case .root:
            fatalError("Unbalanced calls to start() and end(_:)")

        case .nested(.root(let rootSymbols), _):
            self = .root(symbols: rootSymbols + newSymbols)

        case .nested(.nested(let parent, let parentSymbols), _):
            self = .nested(parent: parent, symbols: parentSymbols + newSymbols)
        }
    }

    /// Symbols at current scope
    var symbols: [any SwiftInterfaceElement] {
        switch self {
        case .root(let symbols): return symbols
        case .nested(_, let symbols): return symbols
        }
    }
}
