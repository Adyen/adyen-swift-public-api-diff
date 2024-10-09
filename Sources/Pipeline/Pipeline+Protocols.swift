//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

enum ProjectType {
    case swiftPackage
    case xcodeProject(scheme: String)
}

protocol ProjectSetupHelping {
    func setup(_ projectSource: ProjectSource, projectType: ProjectType) async throws -> URL
}

struct ABIGeneratorOutput: Equatable {
    let targetName: String
    let abiJsonFileUrl: URL
}

protocol ABIGenerating {
    func generate(for projectDirectory: URL, scheme: String?, description: String) throws -> [ABIGeneratorOutput]
}

protocol SwiftInterfaceParsing {
    func parse(source: String, moduleName: String) -> any SwiftInterfaceElement
}

protocol SwiftInterfaceAnalyzing {
    func analyze(old: some SwiftInterfaceElement, new: some SwiftInterfaceElement) throws -> [Change]
}

protocol OutputGenerating {
    func generate(
        from changesPerTarget: [String: [Change]],
        allTargets: [String],
        oldVersionName: String,
        newVersionName: String,
        warnings: [String]
    ) throws -> String
}

struct ProjectAnalyzerResult {
    let changes: [Change]
    let warnings: [String]
}

protocol ProjectAnalyzing {
    /// Analyzes whether or not the available libraries changed between the old and new version
    func analyze(
        oldProjectUrl: URL,
        newProjectUrl: URL
    ) throws -> ProjectAnalyzerResult
}

protocol Logging {
    
    func log(_ message: String, from subsystem: String)
    func debug(_ message: String, from subsystem: String)
}
