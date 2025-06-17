//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADOutputGenerator
import XCTest

class OutputGeneratorTests: XCTestCase {

    func test_noChanges_singleModule() {

        let expectedOutput = """
        # ✅ No changes detected
        _Comparing `new_source` to `old_source`_

        ---
        **Analyzed targets:** Target_1
        """

        let outputGenerator = MarkdownOutputGenerator()
        let output = outputGenerator.generate(
            from: [:],
            allTargets: ["Target_1"],
            oldVersionName: "old_source",
            newVersionName: "new_source",
            warnings: []
        )
        
        XCTAssertEqual(output, expectedOutput)
    }

    func test_oneChange_singleModule() {

        let expectedOutput = """
        # 👀 1 public change detected
        _Comparing `new_source` to `old_source`_
        <table><tr><td>❇️</td><td><b>1 Addition</b></td></tr></table>
        
        ---
        ## `Target_1`
        #### ❇️ Added
        ```swift
        Some Addition
        ```

        ---
        **Analyzed targets:** Target_1
        """

        let outputGenerator = MarkdownOutputGenerator()

        let output = outputGenerator.generate(
            from: ["Target_1": [.init(changeType: .addition(description: "Some Addition"), parentPath: "")]],
            allTargets: ["Target_1"],
            oldVersionName: "old_source",
            newVersionName: "new_source",
            warnings: []
        )
        
        XCTAssertEqual(output, expectedOutput)
    }

    func multipleChanges_multipleModules() {

        let expectedOutput = """
        # ⚠️ 4 public changes detected ⚠️
        _Comparing `new_source` to `old_repository @ old_branch`_
        <table><tr><td>❇️</td><td><b>2 Additions</b></td></tr><tr><td>❌</td><td><b>2 Removals</b></td></tr></table>

        ---
        ## `Target_1`
        #### ❇️ Added
        ```swift
        Some Addition
        ```
        #### ❌ Removed
        ```swift
        Some Removal
        ```
        ## `Target_2`
        #### ❇️ Added
        ```swift
        Another Addition
        ```
        #### ❌ Removed
        ```swift
        Another Removal
        ```

        ---
        **Analyzed targets:** Target_1, Target_2
        """

        let outputGenerator = MarkdownOutputGenerator()

        let output = outputGenerator.generate(
            from: [
                "Target_1": [
                    .init(changeType: .addition(description: "Some Addition"), parentPath: ""),
                    .init(changeType: .removal(description: "Some Removal"), parentPath: "")
                ],
                "Target_2": [
                    .init(changeType: .addition(description: "Another Addition"), parentPath: ""),
                    .init(changeType: .removal(description: "Another Removal"), parentPath: "")
                ]
            ],
            allTargets: ["Target_1", "Target_2"],
            oldVersionName: "old_repository @ old_branch",
            newVersionName: "new_source",
            warnings: []
        )
        
        XCTAssertEqual(output, expectedOutput)
    }
    
    struct AllTargetsExpectation {
        let allTargets: [String]?
        let expectedTitle: String
        let expectedTargetSection: String
    }

    func test_allTargets_shouldChangeOutputAsExpected() {
        
        let testExpectations: [AllTargetsExpectation] = [
            .init(
                allTargets: [],
                expectedTitle: "‼️ No analyzable targets detected",
                expectedTargetSection: ""
            ),
            .init(
                allTargets: nil,
                expectedTitle: "✅ No changes detected",
                expectedTargetSection: ""
            ),
            .init(
                allTargets: ["SomeTarget"],
                expectedTitle: "✅ No changes detected",
                expectedTargetSection: "\n**Analyzed targets:** SomeTarget"
            )
        ]
        
        testExpectations.forEach { argument in
            allTargets_shouldChangeOutputAsExpected(argument: argument)
        }
    }
    
    private func allTargets_shouldChangeOutputAsExpected(argument: AllTargetsExpectation) {
        
        let expectedOutput = """
        # \(argument.expectedTitle)
        _Comparing `new_source` to `old_repository @ old_branch`_

        ---\(argument.expectedTargetSection)
        """
        
        let outputGenerator = MarkdownOutputGenerator()
        
        let output = outputGenerator.generate(
            from: [:],
            allTargets: argument.allTargets,
            oldVersionName: "old_repository @ old_branch",
            newVersionName: "new_source",
            warnings: []
        )
        
        XCTAssertEqual(output, expectedOutput)
    }
}
