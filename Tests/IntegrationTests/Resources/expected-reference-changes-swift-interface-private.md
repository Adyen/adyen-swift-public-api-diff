# ⚠️ 57 public changes detected ⚠️
_Comparing `new_private` to `old_private`_
<table><tr><td>❇️</td><td><b>33 Additions</b></td></tr><tr><td>🔀</td><td><b>22 Modifications</b></td></tr><tr><td>❌</td><td><b>2 Removals</b></td></tr></table>

---
## `ReferencePackage`
#### ❇️ Added
```javascript
@resultBuilder
public struct SomeResultBuilder {
  public static func buildBlock(_ components: Swift.String) -> Swift.String
}
```
```javascript
public enum RawValueEnum: Swift.Equatable, Swift.Hashable, Swift.RawRepresentable, Swift.String {
  case one
  case two
  public init?(rawValue: Swift.String)
  public typealias RawValue = Swift.String
  public var rawValue: Swift.String { get }
}
```
```javascript
public protocol ParentProtocol {
  associatedtype Iterator: Swift.Collection
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
}
```
```javascript
public protocol ParentProtocol<ParentType> {
  associatedtype Iterator: Swift.Collection
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
}
```
```javascript
public protocol ProtocolWithDefaultImplementation {
  func function() -> Swift.String
}
```
```javascript
public protocol SimpleProtocol
```
#### 🔀 Modified
```javascript
// From
@_spi(SystemProgrammingInterface)
open class OpenSpiConformingClass: ReferencePackage.CustomProtocol

// To
@_spi(SystemProgrammingInterface)
open class OpenSpiConformingClass<T>: ReferencePackage.CustomProtocol where T : Swift.Strideable

/**
Changes:
- Added generic parameter description `<T>`
- Added generic where clause `where T : Swift.Strideable`
*/
```
```javascript
// From
public actor CustomActor

// To
public actor CustomActor: ReferencePackage.SimpleProtocol

/**
Changes:
- Added inheritance `ReferencePackage.SimpleProtocol`
*/
```
```javascript
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
```javascript
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
```javascript
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
### `Array`
#### ❇️ Added
```javascript
extension Swift.Array {
  public subscript(safe index: Swift.Int) -> Element? { get }
}
```
### `CustomClass`
#### ❇️ Added
```javascript
final public let a: Swift.Int { get }
```
```javascript
final public let b: Swift.Int { get }
```
```javascript
final public let c: Swift.Int { get }
```
```javascript
final public let d: Swift.Double { get }
```
```javascript
public subscript(index: Swift.Int) -> T? { get set }
```
```javascript
public var lazyVar: Swift.String { get set }
```
#### 🔀 Modified
```javascript
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
```javascript
// From
convenience public init(value: T)

// To
convenience public init!(value: T)

/**
Changes:
- Added optional mark `!`
*/
```
```javascript
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
```javascript
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
```javascript
case a
```
```javascript
case b
```
```javascript
case c
```
```javascript
case caseWithNamedString(title: T)
```
```javascript
case d
```
```javascript
case e(ReferencePackage.CustomEnum<T>.NestedStructInExtension)
```
```javascript
extension ReferencePackage.CustomEnum where T == Swift.String {
  public var titleOfCaseWithNamedString: Swift.String? { get }
}
```
```javascript
public struct NestedStructInExtension: Swift.CustomStringConvertible {
  public init(string: Swift.String = "Hello")
  public let string: Swift.String { get }
  public var description: Swift.String { get }
}
```
#### 🔀 Modified
```javascript
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
```javascript
// From
indirect case recursive(ReferencePackage.CustomEnum)

// To
indirect case recursive(ReferencePackage.CustomEnum<T>)

/**
Changes:
- Added parameter `ReferencePackage.CustomEnum<T>`
- Removed parameter `ReferencePackage.CustomEnum`
*/
```
#### ❌ Removed
```javascript
case caseWithString(Swift.String)
```
### `CustomProtocol`
#### ❇️ Added
```javascript
associatedtype AnotherAssociatedType: Swift.Strideable
```
```javascript
associatedtype AnotherAssociatedType: Swift.Strideable
```
```javascript
associatedtype CustomAssociatedType: Swift.Equatable
```
```javascript
associatedtype CustomAssociatedType: Swift.Equatable
```
#### 🔀 Modified
```javascript
// From
func function() -> any Swift.Equatable

// To
func function() -> Self.CustomAssociatedType

/**
Changes:
- Modified return type from `any Swift.Equatable` to `Self.CustomAssociatedType`
*/
```
```javascript
// From
var getSetVar: any Swift.Equatable { get set }

// To
var getSetVar: Self.AnotherAssociatedType { get set }

/**
Changes:
- Modified type from `any Swift.Equatable` to `Self.AnotherAssociatedType`
*/
```
```javascript
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
```javascript
typealias CustomAssociatedType = Swift.Equatable
```
### `CustomStruct`
#### ❇️ Added
```javascript
@available(macOS, unavailable, message: "Unavailable on macOS")
public struct NestedStruct {
  @available(*, deprecated, renamed: "nestedVar")
  public let nestedLet: Swift.String { get }
  @available(swift 5.9)
  public let nestedVar: Swift.String { get }
}
```
```javascript
public typealias AnotherAssociatedType = Swift.Double
```
```javascript
public typealias CustomAssociatedType = Swift.Int
```
```javascript
public typealias Iterator = [ReferencePackage.CustomStruct<T>.AnotherAssociatedType]
```
```javascript
public typealias ParentType = Swift.Double
```
#### 🔀 Modified
```javascript
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
```javascript
// From
public var getSetVar: any Swift.Equatable

// To
public var getSetVar: Swift.Double

/**
Changes:
- Modified type from `any Swift.Equatable` to `Swift.Double`
*/
```
```javascript
// From
public var getVar: any Swift.Equatable

// To
public var getVar: Swift.Int

/**
Changes:
- Modified type from `any Swift.Equatable` to `Swift.Int`
*/
```
### `OpenSpiConformingClass`
#### ❇️ Added
```javascript
@_spi(SystemProgrammingInterface)
public typealias AnotherAssociatedType = T
```
```javascript
@_spi(SystemProgrammingInterface)
public typealias Iterator = [Swift.Double]
```
```javascript
@_spi(SystemProgrammingInterface)
public typealias ParentType = Swift.Double
```
#### 🔀 Modified
```javascript
// From
@_spi(SystemProgrammingInterface)
@inlinable
public func function() -> ReferencePackage.OpenSpiConformingClass.CustomAssociatedType

// To
@_spi(SystemProgrammingInterface)
@inlinable
public func function() -> T

/**
Changes:
- Modified return type from `ReferencePackage.OpenSpiConformingClass.CustomAssociatedType` to `T`
*/
```
```javascript
// From
@_spi(SystemProgrammingInterface)
public init(
  getSetVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType,
  getVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType
)

// To
@_spi(SystemProgrammingInterface)
public init(
  getSetVar: T,
  getVar: T
)

/**
Changes:
- Added parameter `getSetVar: T`
- Added parameter `getVar: T`
- Removed parameter `getSetVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType`
- Removed parameter `getVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType`
*/
```
```javascript
// From
@_spi(SystemProgrammingInterface)
public typealias CustomAssociatedType = any Swift.Equatable

// To
@_spi(SystemProgrammingInterface)
public typealias CustomAssociatedType = T

/**
Changes:
- Modified assignment from `any Swift.Equatable` to `T`
*/
```
```javascript
// From
@_spi(SystemProgrammingInterface)
public var getSetVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType

// To
@_spi(SystemProgrammingInterface)
public var getSetVar: T

/**
Changes:
- Modified type from `ReferencePackage.OpenSpiConformingClass.CustomAssociatedType` to `T`
*/
```
```javascript
// From
@_spi(SystemProgrammingInterface)
public var getVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType

// To
@_spi(SystemProgrammingInterface)
public var getVar: T

/**
Changes:
- Modified type from `ReferencePackage.OpenSpiConformingClass.CustomAssociatedType` to `T`
*/
```

---
**Analyzed targets:** ReferencePackage
