//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADSwiftInterfaceDiff
import Testing

/// Tests for Swift ownership keywords, isolation keywords, and type constraints
/// Covers: borrowing, consuming, inout, sending, isolated, ~Copyable, ~Escapable
@Suite
struct OwnershipKeywordsTests {
    
    @Test func borrowingKeywordInFunctionParameter() throws {
        let swiftCode = """
        public func testFunc(_ param: borrowing String) -> String {
            return param
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "testFunc")
        #expect(function.parameters.count == 1)
        #expect(function.parameters[0].type == "borrowing String")
        #expect(function.parameters[0].firstName == "_")
        
        // Verify the parameter appears in the description
        let description = function.description
        #expect(description.contains("borrowing String"), "Description should contain 'borrowing String'")
    }
    
    @Test func consumingKeywordInFunctionParameter() throws {
        let swiftCode = """
        public func consume(_ param: consuming String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "consume")
        #expect(function.parameters.count == 1)
        #expect(function.parameters[0].type == "consuming String")
        
        // Verify the parameter appears in the description
        let description = function.description
        #expect(description.contains("consuming String"), "Description should contain 'consuming String'")
    }
    
    @Test func inoutKeywordInFunctionParameter() throws {
        let swiftCode = """
        public func mutate(_ param: inout String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "mutate")
        #expect(function.parameters.count == 1)
        #expect(function.parameters[0].type == "inout String")
        
        // Verify the parameter appears in the description
        let description = function.description
        #expect(description.contains("inout String"), "Description should contain 'inout String'")
    }
    
    @Test func ownershipKeywordChangeDetection() throws {
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
        
        let oldFunction = try #require(oldRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        let newFunction = try #require(newRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        
        // Test that differences are detected
        let differences = newFunction.differences(to: oldFunction)
        
        #expect(!differences.isEmpty, "Should detect parameter type change")
        #expect(
            differences.contains(where: { $0.contains("borrowing") }),
            "Difference should mention 'borrowing' keyword"
        )
    }
    
    @Test func consumingKeywordRemovalDetection() throws {
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
        
        let oldFunction = try #require(oldRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        let newFunction = try #require(newRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        
        // Test that differences are detected
        let differences = newFunction.differences(to: oldFunction)
        
        #expect(!differences.isEmpty, "Should detect parameter type change")
        #expect(
            differences.contains(where: { $0.contains("consuming") }),
            "Difference should mention 'consuming' keyword"
        )
    }
    
    @Test func multipleOwnershipKeywordsInFunction() throws {
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
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "process")
        #expect(function.parameters.count == 3)
        #expect(function.parameters[0].type == "borrowing String")
        #expect(function.parameters[1].type == "consuming Int")
        #expect(function.parameters[2].type == "inout Double")
        
        // Verify all ownership keywords appear in the description
        let description = function.description
        #expect(description.contains("borrowing String"))
        #expect(description.contains("consuming Int"))
        #expect(description.contains("inout Double"))
    }
    
    // MARK: - Inout Add/Remove Tests
    
    @Test func inoutKeywordAddition() throws {
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
        
        let oldFunction = try #require(oldRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        let newFunction = try #require(newRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        
        let differences = newFunction.differences(to: oldFunction)
        
        #expect(!differences.isEmpty, "Should detect parameter type change")
        #expect(
            differences.contains(where: { $0.contains("inout") }),
            "Difference should mention 'inout' keyword"
        )
    }
    
    @Test func inoutKeywordRemoval() throws {
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
        
        let oldFunction = try #require(oldRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        let newFunction = try #require(newRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        
        let differences = newFunction.differences(to: oldFunction)
        
        #expect(!differences.isEmpty, "Should detect parameter type change")
        #expect(
            differences.contains(where: { $0.contains("inout") }),
            "Difference should mention 'inout' keyword"
        )
    }
    
    // MARK: - Sending Keyword Tests
    
    @Test func sendingKeywordInFunctionParameter() throws {
        let swiftCode = """
        public func testFunc(_ param: sending String) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "testFunc")
        #expect(function.parameters.count == 1)
        #expect(function.parameters[0].type == "sending String")
        
        let description = function.description
        #expect(description.contains("sending String"), "Description should contain 'sending String'")
    }
    
    @Test func sendingKeywordAddition() throws {
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
        
        let oldFunction = try #require(oldRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        let newFunction = try #require(newRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        
        let differences = newFunction.differences(to: oldFunction)
        
        #expect(!differences.isEmpty, "Should detect parameter type change")
        #expect(
            differences.contains(where: { $0.contains("sending") }),
            "Difference should mention 'sending' keyword"
        )
    }
    
    // MARK: - Isolated Keyword Tests
    
    @Test func isolatedKeywordInFunctionParameter() throws {
        let swiftCode = """
        public func testFunc(_ actor: isolated MyActor) -> Void {
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "testFunc")
        #expect(function.parameters.count == 1)
        #expect(function.parameters[0].type == "isolated MyActor")
        
        let description = function.description
        #expect(description.contains("isolated MyActor"), "Description should contain 'isolated MyActor'")
    }
    
    // MARK: - Type Constraint Tests (~Copyable, ~Escapable)
    
    @Test func nonCopyableTypeConstraint() throws {
        let swiftCode = """
        public func testFunc<T>(_ value: T) -> T where T: ~Copyable {
            return value
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "testFunc")
        #expect(function.genericWhereClauseDescription != nil)
        #expect(
            function.genericWhereClauseDescription?.contains("~Copyable") ?? false,
            "Should contain ~Copyable constraint"
        )
        
        let description = function.description
        #expect(description.contains("~Copyable"), "Description should contain '~Copyable'")
    }
    
    @Test func nonEscapableTypeConstraint() throws {
        let swiftCode = """
        public func testFunc<T>(_ value: T) -> T where T: ~Escapable {
            return value
        }
        """
        
        let parser = SwiftInterfaceParser()
        let root = parser.parse(source: swiftCode, moduleName: "TestModule")
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "testFunc")
        #expect(function.genericWhereClauseDescription != nil)
        #expect(
            function.genericWhereClauseDescription?.contains("~Escapable") ?? false,
            "Should contain ~Escapable constraint"
        )
        
        let description = function.description
        #expect(description.contains("~Escapable"), "Description should contain '~Escapable'")
    }
    
    @Test func nonCopyableConstraintAddition() throws {
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
        
        let oldFunction = try #require(oldRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        let newFunction = try #require(newRoot.children.first as? SwiftInterfaceFunction, "Expected function elements")
        
        let differences = newFunction.differences(to: oldFunction)
        
        #expect(!differences.isEmpty, "Should detect where clause addition")
        #expect(
            differences.contains(where: { $0.contains("~Copyable") }),
            "Difference should mention '~Copyable' constraint"
        )
    }
    
    // MARK: - Combined Tests
    
    @Test func allParameterModifiersTogether() throws {
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
        
        let function = try #require(root.children.first as? SwiftInterfaceFunction, "Expected a function element")
        
        #expect(function.name == "complexFunc")
        #expect(function.parameters.count == 5)
        
        // Verify all parameter types
        #expect(function.parameters[0].type == "borrowing String")
        #expect(function.parameters[1].type == "consuming Int")
        #expect(function.parameters[2].type == "inout Double")
        #expect(function.parameters[3].type == "sending T")
        #expect(function.parameters[4].type == "isolated MyActor")
        
        // Verify where clause
        #expect(function.genericWhereClauseDescription != nil)
        let whereClause = function.genericWhereClauseDescription ?? ""
        #expect(whereClause.contains("~Copyable"))
        #expect(whereClause.contains("~Escapable"))
        
        // Verify description contains all keywords
        let description = function.description
        #expect(description.contains("borrowing String"))
        #expect(description.contains("consuming Int"))
        #expect(description.contains("inout Double"))
        #expect(description.contains("sending T"))
        #expect(description.contains("isolated MyActor"))
        #expect(description.contains("~Copyable"))
        #expect(description.contains("~Escapable"))
    }
}
