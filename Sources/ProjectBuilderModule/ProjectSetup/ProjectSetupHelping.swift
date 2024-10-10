import Foundation
import CoreModule

public protocol ProjectSetupHelping {
    func setup(_ projectSource: ProjectSource, projectType: ProjectType) async throws -> URL
}
