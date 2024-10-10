import Foundation

public enum ProjectType {
    case swiftPackage
    case xcodeProject(scheme: String)
}
