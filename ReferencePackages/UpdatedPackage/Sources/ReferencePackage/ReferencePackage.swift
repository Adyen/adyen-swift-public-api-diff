//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/**
 An attempt of using all swift language features to make sure that all types of different projects are supported.
 
 Missing information using Swift 5.10
 - No information about `async`, `@MainActor`
 - `class func` is missing a unique feature and only shows as `static`
 */

/**
 TODOs:
 - macro
 - subscriptDeclaration
 */

// MARK: - Protocol with associatedtype

public protocol SimpleProtocol {}

public protocol ParentProtocol<ParentType> {
    associatedtype ParentType: Equatable
    associatedtype Iterator: Collection where Iterator.Element == ParentType
}

public protocol CustomProtocol<CustomAssociatedType, AnotherAssociatedType>: ParentProtocol<Double> {
    associatedtype CustomAssociatedType: Equatable
    associatedtype AnotherAssociatedType: Strideable
    
    var getSetVar: AnotherAssociatedType { get set }
    var getVar: CustomAssociatedType { get }
    func function() -> CustomAssociatedType
}

public struct CustomStruct<T: Strideable>: CustomProtocol {
    public typealias CustomAssociatedType = Int
    public typealias AnotherAssociatedType = Double
    public typealias Iterator = Array<AnotherAssociatedType>
    
    @available(macOS, unavailable, message: "Unavailable on macOS")
    public struct NestedStruct {
        @available(*, deprecated, renamed: "nestedVar")
        public let nestedLet: String = "let"
        @available(swift, introduced: 5.9)
        public let nestedVar: String = "var"
    }
    
    public var getSetVar: Double
    public var getVar: Int
    @discardableResult
    public func function() -> Int { 0 }
}

// MARK: - Generic public class

public class CustomClass<T: Equatable> {
    
    public weak var weakObject: CustomClass?
    public lazy var lazyVar: String = { "I am a lazy" }()
    @_spi(SomeSpi)
    @_spi(AnotherSpi)
    open var computedVar: String { "I am computed" }
    package let constantLet: String = "I'm a let"
    public var optionalVar: T?
    
    public let a = 0, b = 0, c = 0, d: Double = 5.0
    
    @MainActor
    public func asyncThrowingFunc<Element>(_ element: Element) async throws -> Void where Element: Strideable {}
    public func rethrowingFunc(throwingArg: @escaping () throws -> String) rethrows {}
    
    public init(weakObject: CustomClass? = nil, optionalVar: T? = nil) {
        self.weakObject = weakObject
        self.optionalVar = optionalVar
        
        lazyVar = "Great!"
    }
    
    public init?() {}
    
    public convenience init!(value: T) {
        self.init(optionalVar: value)
    }
    
    public subscript(index: Int) -> T? {
        get { optionalVar }
        set { optionalVar = newValue }
    }
}

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < self.count else { return nil }
        return self[index]
    }
}

// MARK: - Generic open class with Protocol conformance and @_spi constraint

@_spi(SystemProgrammingInterface)
open class OpenSpiConformingClass<T: Equatable & Strideable>: CustomProtocol {
    public typealias CustomAssociatedType = T
    public typealias AnotherAssociatedType = T
    public typealias Iterator = Array<Double>
    
    public var getSetVar: T
    public var getVar: T
    @inlinable
    public func function() -> T where T: Equatable { getVar }
    
    public init(getSetVar: T, getVar: T) {
        self.getSetVar = getSetVar
        self.getVar = getVar
    }
}

// MARK: - Package only class

package class PackageOnlyClass {
    public class func classFunc() -> String { "I'm classy" }
    public static func staticFunc() -> String { "I'm static" }
    public static var staticVar: String = "I'm static too"
}

// MARK: - Objc

@_spi(ObjCSpi)
@objc
public class ObjcClass: NSObject {
    public dynamic var dynamicVar: String = "I'm dynamic"
}

// MARK: - Actor

public actor CustomActor: SimpleProtocol {}

// MARK: - Operators

public enum OperatorNamespace: String {
    case someValue = "1"
    
    public static prefix func ++ (_ counter: OperatorNamespace) -> String {
        counter.rawValue
    }
    
    public static postfix func ++ (_ counter: OperatorNamespace) -> String {
        counter.rawValue
    }
}

// MARK: Infix operator with custom precedencegroup

postfix operator &&
prefix operator &&

infix operator &&: CustomPrecedence

precedencegroup CustomPrecedence {
    higherThan: AdditionPrecedence
    lowerThan: MultiplicationPrecedence
    assignment: false
    associativity: left
}

// MARK: - Enums

public enum CustomEnum<T> {
    case normalCase
    case caseWithNamedString(title: T)
    case caseWithTuple(_ foo: String, bar: Int)
    case caseWithBlock((Int) throws -> Void)
    case a, b, c, d, e(NestedStructInExtension)
    
    indirect case recursive(CustomEnum)
}

public enum RawValueEnum: String {
    case one
    case two = "three"
}

extension CustomEnum: SimpleProtocol {
    
    public struct NestedStructInExtension {
        public let string: String
        public init(string: String = "Hello") {
            self.string = string
        }
    }
}

public extension CustomEnum where T == String {
    
    var titleOfCaseWithNamedString: String? {
        if case let .caseWithNamedString(title) = self {
            return title
        }
        return nil
    }
}
