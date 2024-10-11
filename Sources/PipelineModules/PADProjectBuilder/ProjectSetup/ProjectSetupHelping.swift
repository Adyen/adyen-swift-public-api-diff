import Foundation
import PADCore

protocol ProjectSetupHelping {
    func setup(_ projectSource: ProjectSource, projectType: ProjectType) async throws -> URL
}
