import Foundation
import PADCore

protocol ProjectSetupHelping {
    func setup(_ projectSource: PADProjectSource, projectType: PADProjectType) async throws -> URL
}
