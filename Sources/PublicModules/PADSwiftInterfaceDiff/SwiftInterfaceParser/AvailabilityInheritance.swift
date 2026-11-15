//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// An element whose attributes can be adjusted after parsing (e.g. when merging extensions)
protocol SwiftInterfaceAttributedElement: SwiftInterfaceElement {
    var attributes: [String] { get set }
}

extension SwiftInterfaceActor: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceAssociatedType: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceClass: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceEnum: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceEnumCase: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceExtension: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceFunction: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceInitializer: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceProtocol: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceStruct: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceSubscript: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceTypeAlias: SwiftInterfaceAttributedElement {}
extension SwiftInterfaceVar: SwiftInterfaceAttributedElement {}

/// Applies an extension's `@available` attributes to one of its members, following Swift's rule
/// that a member's own availability for a platform takes precedence over the enclosing one.
///
/// e.g. extension `@available(iOS 26.0, tvOS 27.3, *)` + `@available(watchOS, unavailable)` and a member
/// declaring `@available(tvOS 27.0, *)` → the member gets `@available(iOS 26.0, *)` and
/// `@available(watchOS, unavailable)` in addition to its own attribute.
///
/// Attributes are expected in the parser's normalized form (see `AttributeListSyntax.sanitizedList`).
enum AvailabilityInheritance {

    static func attributes(_ own: [String], inheriting enclosing: [String]) -> [String] {
        let covered = Set(own.flatMap(platforms(of:)))
        var inherited = [String]()

        for attribute in enclosing {
            guard let arguments = availabilityArguments(attribute) else { continue }

            if isShorthand(arguments) {
                // `@available(iOS 26.0, macOS 26.0, *)` - keep only platforms the member doesn't specify
                let remaining = arguments.dropLast().filter { !covered.contains(platformName($0)) }
                guard !remaining.isEmpty else { continue }
                inherited.append("@available(\((remaining + ["*"]).joined(separator: ", ")))")
            } else if let platform = arguments.first, !covered.contains(platformName(platform)) {
                // `@available(tvOS, unavailable)`, `@available(*, deprecated, ...)`, ...
                inherited.append(attribute)
            }
        }

        guard !inherited.isEmpty else { return own }
        return sortedAvailability(inherited.filter { !own.contains($0) } + own)
    }

    /// The platforms an attribute makes a statement about (empty for non-availability attributes)
    private static func platforms(of attribute: String) -> [String] {
        guard let arguments = availabilityArguments(attribute) else { return [] }
        if isShorthand(arguments) { return arguments.dropLast().map(platformName) }
        return arguments.first.map { [platformName($0)] } ?? []
    }

    /// The top level, comma separated arguments of an `@available(...)` attribute
    private static func availabilityArguments(_ attribute: String) -> [String]? {
        guard attribute.hasPrefix("@available("), attribute.hasSuffix(")") else { return nil }
        let body = attribute.dropFirst("@available(".count).dropLast()

        var arguments = [String]()
        var current = ""
        var inString = false
        var previous: Character?
        for character in body {
            if character == "\"" && previous != "\\" { inString.toggle() }
            if character == "," && !inString {
                arguments.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
            previous = character
        }
        arguments.append(current.trimmingCharacters(in: .whitespaces))
        return arguments
    }

    /// `@available(iOS 26.0, macOS 26.0, *)` (as opposed to `@available(iOS, introduced: 26.0)`)
    private static func isShorthand(_ arguments: [String]) -> Bool {
        guard arguments.count >= 2, arguments.last == "*" else { return false }
        return arguments.dropLast().allSatisfy { argument in
            let parts = argument.split(separator: " ")
            return parts.count == 2 && parts[1].first?.isNumber == true
        }
    }

    private static func platformName(_ argument: String) -> String {
        String(argument.split(separator: " ").first ?? "")
    }

    /// Mirrors the parser normalization: `@available` attributes are sorted within their positions
    private static func sortedAvailability(_ attributes: [String]) -> [String] {
        var result = attributes
        let indices = attributes.indices.filter { attributes[$0].hasPrefix("@available(") }
        for (index, attribute) in zip(indices, indices.map { attributes[$0] }.sorted()) {
            result[index] = attribute
        }
        return result
    }
}
