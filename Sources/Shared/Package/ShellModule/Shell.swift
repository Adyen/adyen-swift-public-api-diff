//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import PADLogging

package protocol ShellHandling {

    @discardableResult
    func execute(_ command: String) -> String
}

package struct Shell: ShellHandling {

    private let logger: Logging?
    
    package init(
        logger: Logging?
    ) {
        self.logger = logger
    }

    @discardableResult
    package func execute(_ command: String) -> String {

        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()

        logger?.debug("👾 \(command)", from: String(describing: Self.self))
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
