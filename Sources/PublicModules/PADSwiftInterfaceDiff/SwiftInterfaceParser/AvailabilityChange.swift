//
// Copyright (c) 2026 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import SwiftSyntax

/// Describes the difference between two sets of `@available` attributes per platform,
/// instead of as added/removed attribute strings.
///
/// e.g. `@available(iOS 16.1, *)` + `@available(macOS, unavailable)` + `@available(macCatalyst, unavailable)`
/// → `@available(iOS 16.1, macCatalyst 27.3, macOS 27.3, *)` is described as
/// `Availability added: macOS 27.3, Mac Catalyst 27.3`
enum AvailabilityChange {

    /// The availability of a declaration on one platform (or `*` for all platforms)
    struct Platform: Equatable {
        var introduced: String?
        var isUnavailable = false
        var isNoAsync = false
        var isDeprecated = false
        var deprecated: String?
        var obsoleted: String?
        var message: String?
        var renamed: String?
    }

    /// Change descriptions between two attribute lists (non-availability attributes are ignored).
    /// Returns `nil` if an availability attribute couldn't be interpreted.
    static func describe(old: [String], new: [String]) -> [String]? {
        guard let old = platforms(old), let new = platforms(new) else { return nil }

        var added = [String](), changed = [String](), unavailable = [String](), noLongerUnavailable = [String]()
        var undeclared = [String](), deprecated = [String: [String]](), undeprecated = [String]()
        var deprecationChanged = [String](), messageChanged = [String]()
        var obsoleted = [String](), unobsoleted = [String](), obsoletionChanged = [String]()
        var noasync = [String](), asyncAvailable = [String](), asyncMessageChanged = [String]()

        for platform in sortedPlatforms(Set(old.keys).union(new.keys)) {
            let before = old[platform] ?? Platform()
            let after = new[platform] ?? Platform()
            guard before != after else { continue }
            let name = displayName(platform)

            switch (normalized(before.introduced), normalized(after.introduced)) {
            case (nil, .some): added.append("\(name) \(after.introduced!)")
            case let (.some(old), .some(new)) where old != new: changed.append("\(name) \(before.introduced!) → \(after.introduced!)")
            case (.some, nil) where !after.isUnavailable: undeclared.append(name)
            default: break
            }

            if !before.isUnavailable && after.isUnavailable { unavailable.append(name) }
            if before.isUnavailable && !after.isUnavailable && after.introduced == nil { noLongerUnavailable.append(name) }

            if !before.isNoAsync && after.isNoAsync { noasync.append(name) }
            if before.isNoAsync && !after.isNoAsync { asyncAvailable.append(name) }
            if before.isNoAsync && after.isNoAsync && before.message != after.message {
                asyncMessageChanged.append("\(name): \(before.message ?? "(none)") → \(after.message ?? "(none)")")
            }

            switch (before.isDeprecated, after.isDeprecated) {
            case (false, true):
                deprecated[deprecationDetails(after), default: []].append([name, after.deprecated].compactMap { $0 }.joined(separator: " "))
            case (true, false):
                undeprecated.append(name)
            case (true, true):
                if normalized(before.deprecated) != normalized(after.deprecated) {
                    deprecationChanged.append("\(name) \(before.deprecated ?? "(unversioned)") → \(after.deprecated ?? "(unversioned)")")
                } else if before.message != after.message || before.renamed != after.renamed {
                    messageChanged.append("\(name): \(deprecationDetails(before)) → \(deprecationDetails(after))")
                }
            case (false, false):
                break
            }

            switch (normalized(before.obsoleted), normalized(after.obsoleted)) {
            case (nil, .some): obsoleted.append("\(name) \(after.obsoleted!)")
            case (.some, nil): unobsoleted.append(name)
            case let (.some(old), .some(new)) where old != new: obsoletionChanged.append("\(name) \(before.obsoleted!) → \(after.obsoleted!)")
            default: break
            }
        }

        var descriptions = [String]()
        func add(_ title: String, _ items: [String]) {
            guard !items.isEmpty else { return }
            descriptions.append("\(title): \(items.joined(separator: ", "))")
        }
        add("Availability added", added)
        add("Availability changed", changed)
        add("Marked unavailable", unavailable)
        add("No longer marked unavailable", noLongerUnavailable)
        add("Availability no longer declared", undeclared)
        for (details, platforms) in deprecated.sorted(by: { $0.key < $1.key }) {
            descriptions.append("Deprecated: \(platforms.joined(separator: ", "))\(details.isEmpty ? "" : " (\(details))")")
        }
        add("Deprecation changed", deprecationChanged)
        add("Deprecation message changed", messageChanged)
        add("No longer deprecated", undeprecated)
        add("Obsoleted", obsoleted)
        add("Obsoletion changed", obsoletionChanged)
        add("No longer obsoleted", unobsoleted)
        add("Marked unavailable from async contexts", noasync)
        add("No longer unavailable from async contexts", asyncAvailable)
        add("Async unavailability message changed", asyncMessageChanged)
        return descriptions
    }

    /// A short summary of an attribute list, e.g. `available on iOS 27.3, tvOS 27.3; unavailable on macOS`
    static func summary(_ attributes: [String]) -> String? {
        guard let platforms = platforms(attributes), !platforms.isEmpty else { return nil }
        let sorted = sortedPlatforms(Set(platforms.keys))
        var parts = [String]()
        let available = sorted.compactMap { platform in platforms[platform]?.introduced.map { "\(displayName(platform)) \($0)" } }
        let unavailable = sorted.filter { platforms[$0]?.isUnavailable == true }.map(displayName)
        let deprecated = sorted.filter { platforms[$0]?.isDeprecated == true }.map(displayName)
        let noasync = sorted.filter { platforms[$0]?.isNoAsync == true }.map(displayName)
        if !available.isEmpty { parts.append("available on \(available.joined(separator: ", "))") }
        if !unavailable.isEmpty { parts.append("unavailable on \(unavailable.joined(separator: ", "))") }
        if !deprecated.isEmpty { parts.append("deprecated on \(deprecated.joined(separator: ", "))") }
        if !noasync.isEmpty { parts.append("unavailable from async contexts on \(noasync.joined(separator: ", "))") }
        return parts.isEmpty ? nil : parts.joined(separator: "; ")
    }

    // MARK: - Parsing

    /// Per platform availability of all `@available` attributes in the list
    static func platforms(_ attributes: [String]) -> [String: Platform]? {
        var result = [String: Platform]()
        for attribute in attributes where attribute.hasPrefix("@available(") {
            guard let arguments = AvailabilityInheritance.availabilityArguments(attribute),
                  let first = arguments.first,
                  let platform = AvailabilityInheritance.platformName(first) else { return nil }

            if AvailabilityInheritance.isShorthand(arguments) {
                // @available(iOS 16.1, macOS 27.3, *)
                for argument in arguments.dropLast() {
                    guard case let .availabilityVersionRestriction(platform) = argument.argument else { return nil }
                    result[platform.platform.text, default: Platform()].introduced = platform.version?.trimmedDescription
                }
                continue
            }

            // @available(iOS, introduced: 13.0, deprecated: 16.0, message: "...") / @available(*, unavailable) / @available(swift 5.9)
            var state = result[platform] ?? Platform()
            if case let .availabilityVersionRestriction(platform) = first.argument {
                state.introduced = platform.version?.trimmedDescription
            }

            // When upgrading SwiftSyntax, check SwiftParser's AvailabilityArgumentKind and
            // parseAvailabilityArgumentSpecList for new keywords or argument forms, and extend
            // these switches and their tests. The defaults fall back to raw attribute diffs,
            // so new availability keywords do not necessarily cause a compiler error here.
            for argument in arguments.dropFirst() {
                switch argument.argument {
                case let .token(token):
                    switch token.tokenKind {
                    case .keyword(.unavailable): state.isUnavailable = true
                    case .keyword(.deprecated): state.isDeprecated = true
                    case .keyword(.noasync): state.isNoAsync = true
                    default: return nil
                    }
                case let .availabilityLabeledArgument(argument):
                    switch (argument.label.tokenKind, argument.value) {
                    case let (.keyword(.deprecated), .version(version)):
                        state.isDeprecated = true
                        state.deprecated = version.trimmedDescription
                    case let (.keyword(.introduced), .version(version)): state.introduced = version.trimmedDescription
                    case let (.keyword(.obsoleted), .version(version)): state.obsoleted = version.trimmedDescription
                    case let (.keyword(.message), .string(message)): state.message = message.trimmedDescription
                    case let (.keyword(.renamed), .string(renamed)): state.renamed = renamed.trimmedDescription
                    default: return nil
                    }
                case .availabilityVersionRestriction: return nil
                }
            }
            result[platform] = state
        }
        return result
    }

    // MARK: - Formatting

    private static let platformOrder = ["*", "iOS", "iPadOS", "macOS", "macCatalyst", "tvOS", "watchOS", "visionOS", "anyAppleOS", "swift"]

    private static func sortedPlatforms(_ platforms: Set<String>) -> [String] {
        platforms.sorted { lhs, rhs in
            let lhsIndex = platformOrder.firstIndex(of: lhs) ?? platformOrder.count
            let rhsIndex = platformOrder.firstIndex(of: rhs) ?? platformOrder.count
            return lhsIndex == rhsIndex ? lhs < rhs : lhsIndex < rhsIndex
        }
    }

    private static func displayName(_ platform: String) -> String {
        switch platform {
        case "*": return "all platforms"
        case "macCatalyst": return "Mac Catalyst"
        case "swift": return "Swift"
        default:
            if platform.hasSuffix("ApplicationExtension") {
                return "\(displayName(String(platform.dropLast("ApplicationExtension".count)))) app extensions"
            }
            return platform
        }
    }

    private static func deprecationDetails(_ platform: Platform) -> String {
        [platform.message, platform.renamed.map { "renamed to \($0)" }].compactMap { $0 }.joined(separator: ", ")
    }

    /// `16` and `16.0` denote the same version
    private static func normalized(_ version: String?) -> String? {
        guard var version else { return nil }
        while version.hasSuffix(".0") { version.removeLast(2) }
        return version
    }
}
