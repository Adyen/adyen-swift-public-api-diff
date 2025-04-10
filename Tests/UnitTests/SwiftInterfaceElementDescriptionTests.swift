//
//  SwiftInterfaceElementDescriptionTests.swift
//  public-api-diff
//
//  Created by Alexander Guretzki on 10/04/2025.
//

@testable import PADCore
@testable import PADPackageFileAnalyzer
@testable import PADSwiftInterfaceDiff

import XCTest

class SwiftInterfaceElementDescriptionTests: XCTestCase {
    
    func testRoot() {
        let root = SwiftInterfaceParser.Root(
            moduleName: "ModuleName",
            elements: [
                SwiftInterfaceClass(
                    attributes: ["attribute1", "attribute2"],
                    modifiers: ["modifier1", "modifier2"],
                    name: "ClassName1",
                    genericParameterDescription: "<GenericParameterDescription>",
                    inheritance: ["Inheritance1", "Inheritance2"],
                    genericWhereClauseDescription: "GenericWhereClause",
                    children: []
                ),
                SwiftInterfaceClass(
                    attributes: ["attribute1", "attribute2"],
                    modifiers: ["modifier1", "modifier2"],
                    name: "ClassName2",
                    genericParameterDescription: "<GenericParameterDescription>",
                    inheritance: ["Inheritance1", "Inheritance2"],
                    genericWhereClauseDescription: "GenericWhereClause",
                    children: []
                )
            ]
        )
        
        XCTAssertEqual(root.description, """
attribute1
attribute2
modifier1 modifier2 class ClassName1<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
attribute1
attribute2
modifier1 modifier2 class ClassName2<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(root.description(excl:  [.attributes]), """
modifier1 modifier2 class ClassName1<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
modifier1 modifier2 class ClassName2<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(root.description(excl:  [.modifiers]), """
attribute1
attribute2
class ClassName1<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
attribute1
attribute2
class ClassName2<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(root.description(excl:  [.attributes, .modifiers]), """
class ClassName1<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
class ClassName2<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
""")
    }
    
    func testClassDescription() {
        let element = SwiftInterfaceClass(
            attributes: ["attribute1", "attribute2"],
            modifiers: ["modifier1", "modifier2"],
            name: "ClassName",
            genericParameterDescription: "<GenericParameterDescription>",
            inheritance: ["Inheritance1", "Inheritance2"],
            genericWhereClauseDescription: "GenericWhereClause",
            children: []
        )

        XCTAssertEqual(element.description, """
attribute1
attribute2
modifier1 modifier2 class ClassName<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(element.description(excl: [.attributes]), "modifier1 modifier2 class ClassName<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause")
        XCTAssertEqual(element.description(excl: [.modifiers]), """
attribute1
attribute2
class ClassName<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(element.description(excl: [.attributes, .modifiers]), "class ClassName<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause")
        XCTAssertEqual(element.description(incl: [.modifiers]), "modifier1 modifier2 class ClassName<GenericParameterDescription>: Inheritance1, Inheritance2 GenericWhereClause")
    }
    
    func testExtensionDescription() {
        
        let element = SwiftInterfaceExtension(
            attributes: ["attribute1", "attribute2"],
            modifiers: ["modifier1", "modifier2"],
            extendedType: "ExtendedType",
            inheritance: ["Inheritance1", "Inheritance2"],
            genericWhereClauseDescription: "GenericWhereClause",
            children: []
        )
        
        XCTAssertEqual(element.description, """
attribute1
attribute2
modifier1 modifier2 extension ExtendedType: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(element.description(excl: [.attributes]), "modifier1 modifier2 extension ExtendedType: Inheritance1, Inheritance2 GenericWhereClause")
        XCTAssertEqual(element.description(excl: [.modifiers]), """
attribute1
attribute2
extension ExtendedType: Inheritance1, Inheritance2 GenericWhereClause
""")
        XCTAssertEqual(element.description(excl: [.attributes, .modifiers]), "extension ExtendedType: Inheritance1, Inheritance2 GenericWhereClause")
        XCTAssertEqual(element.description(incl: [.modifiers]), "modifier1 modifier2 extension ExtendedType: Inheritance1, Inheritance2 GenericWhereClause")
    }
}
