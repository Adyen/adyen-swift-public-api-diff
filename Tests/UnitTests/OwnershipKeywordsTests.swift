//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADSwiftInterfaceDiff
import XCTest

/// Tests for Swift ownership keywords, isolation keywords, and type constraints
/// Covers: borrowing, consuming, inout, sending, isolated, ~Copyable, ~Escapable
class OwnershipKeywordsTests: XCTestCase {
    
    func testBorrowingKeywordInFunctionParameter() {
        let swiftCode = """
        public func testFunc(_ param: borrowing String) -> String {
            return param
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "testFunc")
        XCTAssertEqual(function.parameters.count, 1)
        XCTAssertEqual(function.parameters[0].type, "borrowing String")
        XCTAssertEqual(function.parameters[0].firstName, "_")
        
        // Verify the parameter appears in the description
        let description = function.description
        XCTAssertTrue(description.contains("borrowing String"), "Description should contain 'borrowing String'")
    }
    
    func testConsumingKeywordInFunctionParameter() {
        let swiftCode = """
        public func consume(_ param: consuming String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "consume")
        XCTAssertEqual(function.parameters.count, 1)
        XCTAssertEqual(function.parameters[0].type, "consuming String")
        
        // Verify the parameter appears in the description
        let description = function.description
        XCTAssertTrue(description.contains("consuming String"), "Description should contain 'consuming String'")
    }
    
    func testInoutKeywordInFunctionParameter() {
        let swiftCode = """
        public func mutate(_ param: inout String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "mutate")
        XCTAssertEqual(function.parameters.count, 1)
        XCTAssertEqual(function.parameters[0].type, "inout String")
        
        // Verify the parameter appears in the description
        let description = function.description
        XCTAssertTrue(description.contains("inout String"), "Description should contain 'inout String'")
    }
    
    func testOwnershipKeywordChangeDetection() {
        let swiftCodeOld = """
        public func testFunc(_ param: String) -> String {
            return param
        }
        """
        
        let swiftCodeNew = """
        public func testFunc(_ param: borrowing String) -> String {
            return param
        }
        """
        
        let parser = SwiftInterfaceParser()
        let oldRoot = parser.parse(source: swiftCodeOld, moduleName: "TestModule")
        let newRoot = parser.parse(source: swiftCodeNew, moduleName: "TestModule")
        
        guard let oldFunction = oldRoot.children.first as? SwiftInterfaceFunction,
              let newFunction = newRoot.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected function elements")
            return
        }
        
        // Test that differences are detected
        let differences = newFunction.differences(to: oldFunction)
        
        XCTAssertFalse(differences.isEmpty, "Should detect parameter type change")
        XCTAssertTrue(
            differences.contains(where: { $0.contains("borrowing") }),
            "Difference should mention 'borrowing' keyword"
        )
    }
    
    func testConsumingKeywordRemovalDetection() {
        let swiftCodeOld = """
        public func testFunc(_ param: consuming String) -> String {
            return param
        }
        """
        
        let swiftCodeNew = """
        public func testFunc(_ param: String) -> String {
            return param
        }
        """
        
        let parser = SwiftInterfaceParser()
        let oldRoot = parser.parse(source: swiftCodeOld, moduleName: "TestModule")
        let newRoot = parser.parse(source: swiftCodeNew, moduleName: "TestModule")
        
        guard let oldFunction = oldRoot.children.first as? SwiftInterfaceFunction,
              let newFunction = newRoot.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected function elements")
            return
        }
        
        // Test that differences are detected
        let differences = newFunction.differences(to: oldFunction)
        
        XCTAssertFalse(differences.isEmpty, "Should detect parameter type change")
        XCTAssertTrue(
            differences.contains(where: { $0.contains("consuming") }),
            "Difference should mention 'consuming' keyword"
        )
    }
    
    func testMultipleOwnershipKeywordsInFunction() {
        let swiftCode = """
        public func process(
            _ borrowed: borrowing String,
            _ consumed: consuming Int,
            _ mutated: inout Double
        ) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "process")
        XCTAssertEqual(function.parameters.count, 3)
        XCTAssertEqual(function.parameters[0].type, "borrowing String")
        XCTAssertEqual(function.parameters[1].type, "consuming Int")
        XCTAssertEqual(function.parameters[2].type, "inout Double")
        
        // Verify all ownership keywords appear in the description
        let description = function.description
        XCTAssertTrue(description.contains("borrowing String"))
        XCTAssertTrue(description.contains("consuming Int"))
        XCTAssertTrue(description.contains("inout Double"))
    }
    
    // MARK: - Inout Add/Remove Tests
    
    func testInoutKeywordAddition() {
        let swiftCodeOld = """
        public func testFunc(_ param: String) -> Void {
        }
        """
        
        let swiftCodeNew = """
        public func testFunc(_ param: inout String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let oldRoot = parser.parse(source: swiftCodeOld, moduleName: "TestModule")
        let newRoot = parser.parse(source: swiftCodeNew, moduleName: "TestModule")
        
        guard let oldFunction = oldRoot.children.first as? SwiftInterfaceFunction,
              let newFunction = newRoot.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected function elements")
            return
        }
        
        let differences = newFunction.differences(to: oldFunction)
        
        XCTAssertFalse(differences.isEmpty, "Should detect parameter type change")
        XCTAssertTrue(
            differences.contains(where: { $0.contains("inout") }),
            "Difference should mention 'inout' keyword"
        )
    }
    
    func testInoutKeywordRemoval() {
        let swiftCodeOld = """
        public func testFunc(_ param: inout String) -> Void {
        }
        """
        
        let swiftCodeNew = """
        public func testFunc(_ param: String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let oldRoot = parser.parse(source: swiftCodeOld, moduleName: "TestModule")
        let newRoot = parser.parse(source: swiftCodeNew, moduleName: "TestModule")
        
        guard let oldFunction = oldRoot.children.first as? SwiftInterfaceFunction,
              let newFunction = newRoot.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected function elements")
            return
        }
        
        let differences = newFunction.differences(to: oldFunction)
        
        XCTAssertFalse(differences.isEmpty, "Should detect parameter type change")
        XCTAssertTrue(
            differences.contains(where: { $0.contains("inout") }),
            "Difference should mention 'inout' keyword"
        )
    }
    
    // MARK: - Sending Keyword Tests
    
    func testSendingKeywordInFunctionParameter() {
        let swiftCode = """
        public func testFunc(_ param: sending String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "testFunc")
        XCTAssertEqual(function.parameters.count, 1)
        XCTAssertEqual(function.parameters[0].type, "sending String")
        
        let description = function.description
        XCTAssertTrue(description.contains("sending String"), "Description should contain 'sending String'")
    }
    
    func testSendingKeywordAddition() {
        let swiftCodeOld = """
        public func testFunc(_ param: String) -> Void {
        }
        """
        
        let swiftCodeNew = """
        public func testFunc(_ param: sending String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let oldRoot = parser.parse(source: swiftCodeOld, moduleName: "TestModule")
        let newRoot = parser.parse(source: swiftCodeNew, moduleName: "TestModule")
        
        guard let oldFunction = oldRoot.children.first as? SwiftInterfaceFunction,
              let newFunction = newRoot.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected function elements")
            return
        }
        
        let differences = newFunction.differences(to: oldFunction)
        
        XCTAssertFalse(differences.isEmpty, "Should detect parameter type change")
        XCTAssertTrue(
            differences.contains(where: { $0.contains("sending") }),
            "Difference should mention 'sending' keyword"
        )
    }
    
    // MARK: - Isolated Keyword Tests
    
    func testIsolatedKeywordInFunctionParameter() {
        let swiftCode = """
        public func testFunc(_ actor: isolated MyActor) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "testFunc")
        XCTAssertEqual(function.parameters.count, 1)
        XCTAssertEqual(function.parameters[0].type, "isolated MyActor")
        
        let description = function.description
        XCTAssertTrue(description.contains("isolated MyActor"), "Description should contain 'isolated MyActor'")
    }
    
    // MARK: - Type Constraint Tests (~Copyable, ~Escapable)
    
    func testNonCopyableTypeConstraint() {
        let swiftCode = """
        public func testFunc<T>(_ value: T) -> T where T: ~Copyable {
            return value
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "testFunc")
        XCTAssertNotNil(function.genericWhereClauseDescription)
        XCTAssertTrue(
            function.genericWhereClauseDescription?.contains("~Copyable") ?? false,
            "Should contain ~Copyable constraint"
        )
        
        let description = function.description
        XCTAssertTrue(description.contains("~Copyable"), "Description should contain '~Copyable'")
    }
    
    func testNonEscapableTypeConstraint() {
        let swiftCode = """
        public func testFunc<T>(_ value: T) -> T where T: ~Escapable {
            return value
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "testFunc")
        XCTAssertNotNil(function.genericWhereClauseDescription)
        XCTAssertTrue(
            function.genericWhereClauseDescription?.contains("~Escapable") ?? false,
            "Should contain ~Escapable constraint"
        )
        
        let description = function.description
        XCTAssertTrue(description.contains("~Escapable"), "Description should contain '~Escapable'")
    }
    
    func testNonCopyableConstraintAddition() {
        let swiftCodeOld = """
        public func testFunc<T>(_ value: T) -> T {
            return value
        }
        """
        
        let swiftCodeNew = """
        public func testFunc<T>(_ value: T) -> T where T: ~Copyable {
            return value
        }
        """
        
        let parser = SwiftInterfaceParser()
        let oldRoot = parser.parse(source: swiftCodeOld, moduleName: "TestModule")
        let newRoot = parser.parse(source: swiftCodeNew, moduleName: "TestModule")
        
        guard let oldFunction = oldRoot.children.first as? SwiftInterfaceFunction,
              let newFunction = newRoot.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected function elements")
            return
        }
        
        let differences = newFunction.differences(to: oldFunction)
        
        XCTAssertFalse(differences.isEmpty, "Should detect where clause addition")
        XCTAssertTrue(
            differences.contains(where: { $0.contains("~Copyable") }),
            "Difference should mention '~Copyable' constraint"
        )
    }
    
    // MARK: - Combined Tests
    
    func testAllParameterModifiersTogether() {
        let swiftCode = """
        public func complexFunc<T, U>(
            _ borrowed: borrowing String,
            _ consumed: consuming Int,
            _ mutated: inout Double,
            _ sent: sending T,
            _ actor: isolated MyActor
        ) -> U where T: ~Copyable, U: ~Escapable {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        guard let function = root.children.first as? SwiftInterfaceFunction else {
            XCTFail("Expected a function element")
            return
        }
        
        XCTAssertEqual(function.name, "complexFunc")
        XCTAssertEqual(function.parameters.count, 5)
        
        // Verify all parameter types
        XCTAssertEqual(function.parameters[0].type, "borrowing String")
        XCTAssertEqual(function.parameters[1].type, "consuming Int")
        XCTAssertEqual(function.parameters[2].type, "inout Double")
        XCTAssertEqual(function.parameters[3].type, "sending T")
        XCTAssertEqual(function.parameters[4].type, "isolated MyActor")
        
        // Verify where clause
        XCTAssertNotNil(function.genericWhereClauseDescription)
        let whereClause = function.genericWhereClauseDescription ?? ""
        XCTAssertTrue(whereClause.contains("~Copyable"))
        XCTAssertTrue(whereClause.contains("~Escapable"))
        
        // Verify description contains all keywords
        let description = function.description
        XCTAssertTrue(description.contains("borrowing String"))
        XCTAssertTrue(description.contains("consuming Int"))
        XCTAssertTrue(description.contains("inout Double"))
        XCTAssertTrue(description.contains("sending T"))
        XCTAssertTrue(description.contains("isolated MyActor"))
        XCTAssertTrue(description.contains("~Copyable"))
        XCTAssertTrue(description.contains("~Escapable"))
    }
}
