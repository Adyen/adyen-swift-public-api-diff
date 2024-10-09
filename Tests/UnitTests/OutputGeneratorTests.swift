//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@testable import public_api_diff
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
            oldVersionName: ProjectSource.local(path: "old_source").description,
            newVersionName: ProjectSource.local(path: "new_source").description,
            warnings: []
        )
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_oneChange_singleModule() {
        
        let expectedOutput = """
        # 👀 1 public change detected
        _Comparing `new_source` to `old_source`_

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
            oldVersionName: ProjectSource.local(path: "old_source").description,
            newVersionName: ProjectSource.local(path: "new_source").description,
            warnings: []
        )
        XCTAssertEqual(output, expectedOutput)
    }
    
    func test_multipleChanges_multipleModules() {
        
        let expectedOutput = """
        # 👀 4 public changes detected
        _Comparing `new_source` to `old_repository @ old_branch`_

        ---
        ## `Target_1`
        #### ❇️ Added
        ```javascript
        Some Addition
        ```
        #### 😶‍🌫️ Removed
        ```javascript
        Some Removal
        ```
        ## `Target_2`
        #### ❇️ Added
        ```javascript
        Another Addition
        ```
        #### 😶‍🌫️ Removed
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
            oldVersionName: ProjectSource.remote(branch: "old_branch", repository: "old_repository").description,
            newVersionName: ProjectSource.local(path: "new_source").description,
            warnings: []
        )
        XCTAssertEqual(output, expectedOutput)
    }
}
