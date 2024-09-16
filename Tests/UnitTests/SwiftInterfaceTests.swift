//
//  File.swift
//  
//
//  Created by Alexander Guretzki on 16/09/2024.
//

@testable import public_api_diff
import XCTest

import SwiftSyntax
import SwiftParser

class SwiftInterfaceTests: XCTestCase {
    
    func test_swiftinterface() throws {
        
        // Unfortunately we can't use packages as Test Resources, so we put it in a `ReferencePackages` directory on root
        guard let projectRoot = #file.replacingOccurrences(of: "relatve/path/to/file", with: "").split(separator: "/Tests/").first else {
            XCTFail("Cannot find root directory")
            return
        }
        
        let referencePackagesRoot = URL(filePath: String(projectRoot)).appending(path: "ReferencePackages")
        
        let expectedOutput: String = try {
            let expectedOutputFilePath = try XCTUnwrap(Bundle.module.path(forResource: "expected-reference-changes", ofType: "md"))
            let expectedOutputData = try XCTUnwrap(FileManager.default.contents(atPath: expectedOutputFilePath))
            return try XCTUnwrap(String(data: expectedOutputData, encoding: .utf8))
        }()
        
        let oldSource: String = try {
            let oldReferencePackageDirectory = referencePackagesRoot.appending(path: "ReferencePackage")
            let interfaceFilePath = try XCTUnwrap(oldReferencePackageDirectory.appending(path: "Sources/ReferencePackage/ReferencePackage.swift"))
            let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: interfaceFilePath.path()))
            return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
        }()
        
        let newSource: String = try {
            let newReferencePackageDirectory = referencePackagesRoot.appending(path: "UpdatedPackage")
            let interfaceFilePath = try XCTUnwrap(newReferencePackageDirectory.appending(path: "Sources/ReferencePackage/ReferencePackage.swift"))
            let interfaceFileContent = try XCTUnwrap(FileManager.default.contents(atPath: interfaceFilePath.path()))
            return try XCTUnwrap(String(data: interfaceFileContent, encoding: .utf8))
        }()
        
        let oldRoot = SDKDump(
            root: .init(
                kind: .root,
                name: "TopLevel",
                printedName: "TopLevel",
                children: SwiftInterfaceVisitor.parse(source: oldSource)
            )
        )
        
        let newRoot = SDKDump(
            root: .init(
                kind: .root,
                name: "TopLevel",
                printedName: "TopLevel",
                children: SwiftInterfaceVisitor.parse(source: newSource)
            )
        )
        
        let changes = SDKDumpAnalyzer().analyze(old: oldRoot, new: newRoot)
        let markdownOutput = MarkdownOutputGenerator().generate(
            from: ["ReferencePackage": changes],
            allTargets: ["ReferencePackage"],
            oldSource: .local(path: "/.../.../ReferencePackage"),
            newSource: .local(path: "/.../.../UpdatedPackage"),
            warnings: []
        )
        
        XCTAssertEqual(markdownOutput, expectedOutput)
    }
}

/**
 Inspired by: https://github.com/sdidla/Hatch/blob/main/Sources/Hatch/SymbolParser.swift
 */
class SwiftInterfaceVisitor: SyntaxVisitor {
    
    /*
     if hasDiscardableResult { components += ["@discardableResult"] }
     if isObjcAccessible { components += ["@objc"] }
     if isInlinable { components += ["@inlinable"] }
     if isOverride { components += ["override"] }
     if declKind != .import && declKind != .case {
         if isOpen {
             components += ["open"]
         } else if isInternal {
             components += ["internal"]
         } else {
             components += ["public"]
         }
     }
     if isFinal { components += ["final"] }
     if isIndirect { components += ["indirect"] }
     if isRequired { components += ["required"] }
     if isStatic { components += ["static"] }
     if isConvenienceInit { components += ["convenience"] }
     if isDynamic { components += ["dynamic"] }
     if isPrefix { components += ["prefix"] }
     if isPostfix { components += ["postfix"] }
     if isInfix { components += ["infix"] }
     */
    
    private var scope: Scope = .root(symbols: [])
    
    static public func parse(source: String) -> [SDKDump.Element] {
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
    public func endScopeAndAddSymbol(makeSymbolWithChildrenInScope: (_ children: [SDKDump.Element]) -> SDKDump.Element) {
        scope.end(makeSymbolWithChildrenInScope: makeSymbolWithChildrenInScope)
    }
    
    // MARK: Class
    
    open override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    open override func visitPost(_ node: ClassDeclSyntax) {
        let name: String = node.name.text
        
        endScopeAndAddSymbol { children in
            SDKDump.Element(
                kind: .class,
                name: name,
                printedName: name,
                declKind: .class,
                children: children, 
                spiGroupNames: node.attributes.spiGroupNames,
                declAttributes: node.attributes.declAttributes,
                conformances: node.inheritanceClause?.inheritedTypes.conformances
            )
        }
    }
    
    // MARK: Struct
    
    open override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    open override func visitPost(_ node: StructDeclSyntax) {
        let name: String = node.name.text
        
        endScopeAndAddSymbol { children in
            SDKDump.Element(
                kind: .struct,
                name: name,
                printedName: name,
                declKind: .struct,
                children: children,
                spiGroupNames: node.attributes.spiGroupNames,
                declAttributes: node.attributes.declAttributes,
                conformances: node.inheritanceClause?.inheritedTypes.conformances
            )
        }
    }
    
    // MARK: Var
    
    open override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }

    open override func visitPost(_ node: VariableDeclSyntax) {
        let components = node.bindings.description.split(separator: ":")
        guard components.count == 2 else { return }
        let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let type = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        endScopeAndAddSymbol { children in
            let varElement = SDKDump.Element(
                kind: .var,
                name: name,
                printedName: name,
                declKind: .var,
                isLet: node.bindingSpecifier.text == "let",
                children: [.init(kind: .typeNominal, name: type, printedName: type)],
                spiGroupNames: node.attributes.spiGroupNames,
                declAttributes: node.attributes.declAttributes
            )
            return varElement
        }
    }
    
    // MARK: TypeAlias
    
    open override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: TypeAliasDeclSyntax) {
        let type = SDKDump.Element(
            kind: .typeNominal,
            name: node.initializer.value.description,
            printedName: node.initializer.value.description
        )
        
        endScopeAndAddSymbol { children in
            let varElement = SDKDump.Element(
                kind: .typeAlias,
                name: node.name.text,
                printedName: node.name.text,
                declKind: .typeAlias,
                children: [type],
                spiGroupNames: node.attributes.spiGroupNames,
                declAttributes: node.attributes.declAttributes
            )
            return varElement
        }
    }
    
    // MARK: AssociatedType
    
    open override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: AssociatedTypeDeclSyntax) {
        endScopeAndAddSymbol { children in
            let varElement = SDKDump.Element(
                kind: .associatedtype,
                name: node.name.text,
                printedName: node.name.text,
                declKind: .associatedType,
                children: children,
                spiGroupNames: node.attributes.spiGroupNames,
                declAttributes: node.attributes.declAttributes
            )
            return varElement
        }
    }
    
    // MARK: Function
    
    open override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        startScope()
    }
    
    open override func visitPost(_ node: FunctionDeclSyntax) {
        endScopeAndAddSymbol { children in
            let varElement = SDKDump.Element(
                kind: .func,
                name: node.name.text,
                printedName: node.name.text,
                declKind: .func,
                isThrowing: node.signature.isThrowing,
                children: children,
                spiGroupNames: node.attributes.spiGroupNames,
                declAttributes: node.attributes.declAttributes
            )
            return varElement
        }
    }
}

// MARK: - Convenience

extension AttributeListSyntax {
    private static var spiKeyword: String { "@_spi" }
    
    var spiGroupNames: [String] {
        return self
            .map { $0.trimmedDescription }
            .filter { $0.starts(with: Self.spiKeyword) }
            .map { element in
                element
                    .replacingOccurrences(of: "\(Self.spiKeyword)(", with: "")
                    .replacingOccurrences(of: ")", with: "")
            }
    }
    
    var declAttributes: [String] {
        return self
            .map { $0.trimmedDescription }
            .filter { !$0.starts(with: Self.spiKeyword) }
    }
}

extension InheritedTypeListSyntax {
    
    var conformances: [SDKDump.Element.Conformance] {
        trimmedDescription
            .split(separator: ",")
            .map { .init(printedName: String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
}

extension FunctionSignatureSyntax {
    
    var isThrowing: Bool {
        trimmedDescription.range(of: "throws") != nil
    }
    
    var isAsync: Bool {
        trimmedDescription.range(of: "async") != nil
    }
}

// MARK: - Models

public protocol Symbol {
    var children: [Symbol] { get }
}

indirect enum Scope {

    /// The root scope of a file
    case root(symbols: [SDKDump.Element])
    /// A nested scope, within a parent scope
    case nested(parent: Scope, symbols: [SDKDump.Element])

    /// Starts a new nested scope
    mutating func start() {
        self = .nested(parent: self, symbols: [])
    }

    /// Ends the current scope by adding a new symbol to the scope tree.
    /// The children provided in the closure are the symbols in the scope to be ended
    mutating func end(makeSymbolWithChildrenInScope: (_ children: [SDKDump.Element]) -> SDKDump.Element) {
        let newSymbol = makeSymbolWithChildrenInScope(symbols)

        switch self {
        case .root:
            fatalError("Unbalanced calls to start() and end(_:)")

        case .nested(.root(let rootSymbols), _):
            self = .root(symbols: rootSymbols + [newSymbol])

        case .nested(.nested(let parent, let parentSymbols), _):
            self = .nested(parent: parent, symbols: parentSymbols + [newSymbol])
        }
    }

    /// Symbols at current scope
    var symbols: [SDKDump.Element] {
        switch self {
        case .root(let symbols): return symbols
        case .nested(_, let symbols): return symbols
        }
    }
}
