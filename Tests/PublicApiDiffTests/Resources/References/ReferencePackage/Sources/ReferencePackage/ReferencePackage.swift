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

public protocol CustomProtocol {
    typealias CustomAssociatedType = Equatable
    
    var getSetVar: any CustomAssociatedType { get set }
    var getVar: any CustomAssociatedType { get }
    func function() -> any CustomAssociatedType
}

public struct CustomStruct: CustomProtocol {
    public var getSetVar: any Equatable
    public var getVar: any Equatable
    @discardableResult
    public func function() -> any Equatable { fatalError() }
}

// MARK: - Generic public class

public class CustomClass<T: Equatable> {
    
    public weak var weakObject: CustomClass?
    lazy var lazyVar: String = { "I am a lazy" }()
    @_spi(SomeSpi)
    @_spi(AnotherSpi)
    open var computedVar: String { "I am computed" }
    package let constantLet: String = "I'm a let"
    public var optionalVar: T?
    
    @MainActor
    public func asyncThrowingFunc() async throws {}
    public func rethrowingFunc(throwingArg: @escaping () throws -> String) rethrows {}
    
    public init(weakObject: CustomClass? = nil, optionalVar: T? = nil) {
        self.weakObject = weakObject
        self.optionalVar = optionalVar
    }
    
    public init() {}
    
    public convenience init(value: T) {
        self.init(optionalVar: value)
    }
}

// MARK: - Generic open class with Protocol conformance and @_spi constraint

@_spi(SystemProgrammingInterface)
open class OpenSpiConformingClass: CustomProtocol {
    public typealias CustomAssociatedType = any Equatable
    
    public var getSetVar: CustomAssociatedType
    public var getVar: CustomAssociatedType
    @inlinable
    public func function() -> CustomAssociatedType { fatalError() }
    
    public init(getSetVar: CustomAssociatedType, getVar: CustomAssociatedType) {
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

public actor CustomActor {}

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

public enum CustomEnum {
    case normalCase
    case caseWithString(String)
    case caseWithTuple(String, Int)
    case caseWithBlock((Int) throws -> Void)
    
    indirect case recursive(CustomEnum)
}
