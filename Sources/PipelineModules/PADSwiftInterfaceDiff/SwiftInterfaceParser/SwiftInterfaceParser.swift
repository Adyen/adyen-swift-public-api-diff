import Foundation
import SwiftSyntax
import SwiftParser

/**
 Documentation about DeclSyntax:
 - https://swiftpackageindex.com/swiftlang/swift-syntax/600.0.1/documentation/swiftsyntax/declsyntax
 */
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
    public func endScopeAndAddSymbol(makeElementsWithChildrenInScope: (_ children: [any SwiftInterfaceElement]) -> [any SwiftInterfaceElement]) {
        scope.end(makeElementsWithChildrenInScope: makeElementsWithChildrenInScope)
    }
    
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
    
    // MARK: - Extension
    
    open override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: ExtensionDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - Initializer
    
    open override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: InitializerDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }
    
    // MARK: - Actor
    
    open override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: ActorDeclSyntax) {
        endScopeAndAddSymbol { [node.toInterfaceElement(children: $0)] }
    }
    
    // MARK: - Subscript
    
    open override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: SubscriptDeclSyntax) {
        endScopeAndAddSymbol { _ in [node.toInterfaceElement()] }
    }
}

// MARK: - Scope

fileprivate indirect enum Scope {

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

        case .nested(.root(let rootElements), _):
            self = .root(elements: rootElements + newElements)

        case .nested(.nested(let parent, let parentElements), _):
            self = .nested(parent: parent, elements: parentElements + newElements)
        }
    }

    var elements: [any SwiftInterfaceElement] {
        switch self {
        case .root(let elements): return elements // All child elements recursive from the root
        case .nested(_, let elements): return elements // All child elements recursive from a nested element
        }
    }
}
