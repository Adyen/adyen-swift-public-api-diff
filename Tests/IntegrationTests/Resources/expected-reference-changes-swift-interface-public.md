# ⚠️ 51 public changes detected ⚠️
_Comparing `new_public` to `old_public`_
<table><tr><td>❇️</td><td><b>31 Additions</b></td></tr><tr><td>🔀</td><td><b>16 Modifications</b></td></tr><tr><td>❌</td><td><b>4 Removals</b></td></tr></table>

---
## `ReferencePackage`
#### ❇️ Added
```swift
@available(macOS 14, *)
public enum NewEnumAvailableInVersion17: Swift.Codable, Swift.Equatable, Swift.Hashable, Swift.RawRepresentable, Swift.String {
  @available(macOS 14, *)
  public typealias RawValue = Swift.String
  @available(macOS 15, *)
  public func laterAvailableFunction() -> Swift.Void
  case case1
  public init?(rawValue: Swift.String)
  public var rawValue: Swift.String { get }
}
```
```swift
@resultBuilder
public struct SomeResultBuilder {
  public static func buildBlock(_ components: Swift.String) -> Swift.String
}
```
```swift
public enum RawValueEnum: Swift.Equatable, Swift.Hashable, Swift.RawRepresentable, Swift.String {
  case one
  case two
  public init?(rawValue: Swift.String)
  public typealias RawValue = Swift.String
  public var rawValue: Swift.String { get }
}
```
```swift
public protocol ParentProtocol {
  associatedtype Iterator: Swift.Collection
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
}
```
```swift
public protocol ParentProtocol<ParentType> {
  associatedtype Iterator: Swift.Collection
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
}
```
```swift
public protocol ProtocolWithDefaultImplementation {
  func function() -> Swift.String
}
```
```swift
public protocol SimpleProtocol
```
#### 🔀 Modified
```swift
// From
public actor CustomActor

// To
public actor CustomActor: ReferencePackage.SimpleProtocol

/**
Changes:
- Added inheritance `ReferencePackage.SimpleProtocol`
*/
```
```swift
// From
public enum CustomEnum

// To
public enum CustomEnum<T>: ReferencePackage.SimpleProtocol

/**
Changes:
- Added generic parameter description `<T>`
- Added inheritance `ReferencePackage.SimpleProtocol`
*/
```
```swift
// From
public protocol CustomProtocol

// To
public protocol CustomProtocol<CustomAssociatedType, AnotherAssociatedType>: ReferencePackage.ParentProtocol where Self.ParentType == Swift.Double

/**
Changes:
- Added generic where clause `where Self.ParentType == Swift.Double`
- Added inheritance `ReferencePackage.ParentProtocol`
- Added primary associated type `AnotherAssociatedType`
- Added primary associated type `CustomAssociatedType`
*/
```
```swift
// From
public struct CustomStruct: ReferencePackage.CustomProtocol

// To
public struct CustomStruct<T>: ReferencePackage.CustomProtocol where T : Swift.Strideable

/**
Changes:
- Added generic parameter description `<T>`
- Added generic where clause `where T : Swift.Strideable`
*/
```
#### ❌ Removed
```swift
public struct PublicStructThatIsOnlyAvailableInTheReferencePackage {
  public func bar() -> Swift.Void
  public var foo: Swift.String
}
```
### `Array`
#### ❇️ Added
```swift
extension Swift.Array {
  public subscript(safe index: Swift.Int) -> Element? { get }
}
```
### `CustomClass`
#### ❇️ Added
```swift
final public let a: Swift.Int { get }
```
```swift
final public let b: Swift.Int { get }
```
```swift
final public let c: Swift.Int { get }
```
```swift
final public let d: Swift.Double { get }
```
```swift
public subscript(index: Swift.Int) -> T? { get set }
```
```swift
public var lazyVar: Swift.String { get set }
```
#### 🔀 Modified
```swift
// From
@_Concurrency.MainActor
public func asyncThrowingFunc() async throws -> Swift.Void

// To
@_Concurrency.MainActor
public func asyncThrowingFunc<Element>(_ element: Element) async throws -> Swift.Void where Element : Swift.Strideable

/**
Changes:
- Added generic parameter description `<Element>`
- Added generic where clause `where Element : Swift.Strideable`
- Added parameter `_ element: Element`
*/
```
```swift
// From
convenience public init(value: T)

// To
convenience public init!(value: T)

/**
Changes:
- Added optional mark `!`
*/
```
```swift
// From
public init(
  weakObject: ReferencePackage.CustomClass<T>? = nil,
  optionalVar: T? = nil
)

// To
public init(
  weakObject: ReferencePackage.CustomClass<T>? = nil,
  optionalVar: T? = nil,
  @ReferencePackage.SomeResultBuilder content: () -> Swift.String
)

/**
Changes:
- Added parameter `@ReferencePackage.SomeResultBuilder content: () -> Swift.String`
*/
```
```swift
// From
public init()

// To
public init?()

/**
Changes:
- Added optional mark `?`
*/
```
### `CustomEnum`
#### ❇️ Added
```swift
case a
```
```swift
case b
```
```swift
case c
```
```swift
case caseWithNamedString(title: T)
```
```swift
case d
```
```swift
case e(ReferencePackage.CustomEnum<T>.NestedStructInExtension)
```
```swift
extension ReferencePackage.CustomEnum where T == Swift.String {
  public var titleOfCaseWithNamedString: Swift.String? { get }
}
```
```swift
public struct NestedStructInExtension: Swift.CustomStringConvertible {
  public init(string: Swift.String = "Hello")
  public let string: Swift.String { get }
  public var description: Swift.String { get }
}
```
#### 🔀 Modified
```swift
// From
case caseWithTuple(
  Swift.String,
  Swift.Int
)

// To
case caseWithTuple(
  _: Swift.String,
  bar: Swift.Int
)

/**
Changes:
- Added parameter `_: Swift.String`
- Added parameter `bar: Swift.Int`
- Removed parameter `Swift.Int`
- Removed parameter `Swift.String`
*/
```
```swift
// From
indirect case recursive(ReferencePackage.CustomEnum)

// To
indirect case recursive(ReferencePackage.CustomEnum<T>)

/**
Changes:
- Modified 1st parameter: Changed type from `ReferencePackage.CustomEnum` to `ReferencePackage.CustomEnum<T>`
*/
```
#### ❌ Removed
```swift
case caseWithString(Swift.String)
```
```swift
public enum PublicEnumInExtensionOfCustomEnumThatIsOnlyAvailableInTheReferencePackage: Swift.Equatable, Swift.Hashable {
  case alpha
  case beta
  public func hash(into hasher: inout Swift.Hasher) -> Swift.Void
  public static func ==(
    a: ReferencePackage.CustomEnum.PublicEnumInExtensionOfCustomEnumThatIsOnlyAvailableInTheReferencePackage,
    b: ReferencePackage.CustomEnum.PublicEnumInExtensionOfCustomEnumThatIsOnlyAvailableInTheReferencePackage
  ) -> Swift.Bool
  public var hashValue: Swift.Int { get }
}
```
### `CustomProtocol`
#### ❇️ Added
```swift
associatedtype AnotherAssociatedType: Swift.Strideable
```
```swift
associatedtype AnotherAssociatedType: Swift.Strideable
```
```swift
associatedtype CustomAssociatedType: Swift.Equatable
```
```swift
associatedtype CustomAssociatedType: Swift.Equatable
```
#### 🔀 Modified
```swift
// From
func function() -> any Swift.Equatable

// To
func function() -> Self.CustomAssociatedType

/**
Changes:
- Modified return type from `any Swift.Equatable` to `Self.CustomAssociatedType`
*/
```
```swift
// From
var getSetVar: any Swift.Equatable { get set }

// To
var getSetVar: Self.AnotherAssociatedType { get set }

/**
Changes:
- Modified type from `any Swift.Equatable` to `Self.AnotherAssociatedType`
*/
```
```swift
// From
var getVar: any Swift.Equatable { get }

// To
var getVar: Self.CustomAssociatedType { get }

/**
Changes:
- Modified type from `any Swift.Equatable` to `Self.CustomAssociatedType`
*/
```
#### ❌ Removed
```swift
typealias CustomAssociatedType = Swift.Equatable
```
### `CustomStruct`
#### ❇️ Added
```swift
@available(macOS, unavailable, message: "Unavailable on macOS")
public struct NestedStruct {
  @available(*, deprecated, renamed: "nestedVar")
  public let nestedLet: Swift.String { get }
  @available(swift 5.9)
  public let nestedVar: Swift.String { get }
}
```
```swift
public typealias AnotherAssociatedType = Swift.Double
```
```swift
public typealias CustomAssociatedType = Swift.Int
```
```swift
public typealias Iterator = [ReferencePackage.CustomStruct<T>.AnotherAssociatedType]
```
```swift
public typealias ParentType = Swift.Double
```
#### 🔀 Modified
```swift
// From
@discardableResult
public func function() -> any Swift.Equatable

// To
@discardableResult
public func function() -> Swift.Int

/**
Changes:
- Modified return type from `any Swift.Equatable` to `Swift.Int`
*/
```
```swift
// From
public var getSetVar: any Swift.Equatable

// To
public var getSetVar: Swift.Double

/**
Changes:
- Modified type from `any Swift.Equatable` to `Swift.Double`
*/
```
```swift
// From
public var getVar: any Swift.Equatable

// To
public var getVar: Swift.Int

/**
Changes:
- Modified type from `any Swift.Equatable` to `Swift.Int`
*/
```

---
**Analyzed targets:** ReferencePackage
