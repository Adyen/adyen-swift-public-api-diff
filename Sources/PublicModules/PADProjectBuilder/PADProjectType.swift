import Foundation

public enum PADProjectType {
    case swiftPackage
    case xcodeProject(scheme: String)
}
