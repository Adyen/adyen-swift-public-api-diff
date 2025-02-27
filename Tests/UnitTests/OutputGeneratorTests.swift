//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import PADOutputGenerator
import Testing

class OutputGeneratorTests {

    @Test
    func noChanges_singleModule() {

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
        
        #expect(output == expectedOutput)
    }

    @Test
    func oneChange_singleModule() {

        let expectedOutput = """
        # 👀 1 public change detected
        _Comparing `new_source` to `old_source`_
        <table><tr><td>❇️</td><td><b>1 Addition</b></td></tr></table>
        
        ---
        ## `Target_1`
        #### ❇️ Added
        ```javascript
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
        
        #expect(output == expectedOutput)
    }

    @Test
    func multipleChanges_multipleModules() {

        let expectedOutput = """
        # ⚠️ 4 public changes detected ⚠️
        _Comparing `new_source` to `old_repository @ old_branch`_
        <table><tr><td>❇️</td><td><b>2 Additions</b></td></tr><tr><td>❌</td><td><b>2 Removals</b></td></tr></table>

        ---
        ## `Target_1`
        #### ❇️ Added
        ```javascript
        Some Addition
        ```
        #### ❌ Removed
        ```javascript
        Some Removal
        ```
        ## `Target_2`
        #### ❇️ Added
        ```javascript
        Another Addition
        ```
        #### ❌ Removed
        ```javascript
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
        
        #expect(output == expectedOutput)
    }
    
    struct AllTargetsExpectation {
        let allTargets: [String]?
        let expectedTitle: String
        let expectedTargetSection: String
    }
    
    @Test(
        "allTargets should change the output as expected",
        arguments: [
            AllTargetsExpectation(
                allTargets: [],
                expectedTitle: "‼️ No analyzable targets detected",
                expectedTargetSection: ""
            ),
            AllTargetsExpectation(
                allTargets: nil,
                expectedTitle: "✅ No changes detected",
                expectedTargetSection: ""
            ),
            AllTargetsExpectation(
                allTargets: ["SomeTarget"],
                expectedTitle: "✅ No changes detected",
                expectedTargetSection: "\n**Analyzed targets:** SomeTarget"
            )
        ]
    )
    func allTargets_shouldChangeOutputAsExpected(argument: AllTargetsExpectation) {
        
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
        
        #expect(output == expectedOutput)
    }
}
