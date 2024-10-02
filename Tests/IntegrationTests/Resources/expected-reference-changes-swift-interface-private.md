# 👀 57 public changes detected
_Comparing `/.../.../UpdatedPackage` to `/.../.../ReferencePackage`_

---
## `ReferencePackage`
### `ReferencePackage`
#### ❇️ Added
```javascript
public enum RawValueEnum: Swift.String
{
  case one
  case two
  public init?(rawValue: Swift.String)
  public typealias RawValue = Swift.String
  public var rawValue: Swift.String { get }
}
```
```javascript
public protocol ParentProtocol
{
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
  associatedtype Iterator: Swift.Collection
}
```
```javascript
public protocol ParentProtocol<ParentType>
{
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
  associatedtype Iterator: Swift.Collection
}
```
```javascript
public protocol SimpleProtocol
```
#### 🔀 Changed
```javascript
// From
@_hasMissingDesignatedInitializers public actor CustomActor

// To
@_hasMissingDesignatedInitializers public actor CustomActor: ReferencePackage.SimpleProtocol
```
```javascript
// From
@_spi(SystemProgrammingInterface) open class OpenSpiConformingClass: ReferencePackage.CustomProtocol

// To
@_spi(SystemProgrammingInterface) open class OpenSpiConformingClass<T>: ReferencePackage.CustomProtocol where T : Swift.Strideable
```
```javascript
// From
public enum CustomEnum

// To
public enum CustomEnum<T>
```
```javascript
// From
public protocol CustomProtocol

// To
public protocol CustomProtocol<CustomAssociatedType, AnotherAssociatedType>: ReferencePackage.ParentProtocol where Self.ParentType == Swift.Double
```
```javascript
// From
public struct CustomStruct: ReferencePackage.CustomProtocol

// To
public struct CustomStruct<T>: ReferencePackage.CustomProtocol where T : Swift.Strideable
```
### `ReferencePackage.CustomClass`
#### ❇️ Added
```javascript
final public let a: Swift.Int
```
```javascript
final public let b: Swift.Int
```
```javascript
final public let c: Swift.Int
```
```javascript
final public let d: Swift.Double
```
```javascript
public subscript(index: Swift.Int) -> T? { get set }
```
```javascript
public var lazyVar: Swift.String { get set }
```
#### 🔀 Changed
```javascript
// From
@_Concurrency.MainActor public func asyncThrowingFunc() async throws -> Swift.Void

// To
@_Concurrency.MainActor public func asyncThrowingFunc<Element>(_ element: Element) async throws -> Swift.Void where Element : Swift.Strideable
```
```javascript
// From
convenience public init(value: T)

// To
convenience public init!(value: T)
```
```javascript
// From
public init()

// To
public init?()
```
### `ReferencePackage.CustomEnum`
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
extension ReferencePackage.CustomEnum where T == Swift.String
{
  public var titleOfCaseWithNamedString: Swift.String? { get }
}
```
```javascript
extension ReferencePackage.CustomEnum: ReferencePackage.SimpleProtocol
{
  public struct NestedStructInExtension
  {
      public let string: Swift.String
      public init(string: Swift.String = "Hello")
  }
}
```
#### 🔀 Changed
```javascript
// From
case caseWithTuple(Swift.String, Swift.Int)

// To
case caseWithTuple(_: Swift.String, bar: Swift.Int)
```
```javascript
// From
indirect case recursive(ReferencePackage.CustomEnum)

// To
indirect case recursive(ReferencePackage.CustomEnum<T>)
```
#### 😶‍🌫️ Removed
```javascript
case caseWithString(Swift.String)
```
### `ReferencePackage.CustomProtocol`
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
#### 🔀 Changed
```javascript
// From
func function() -> any Swift.Equatable

// To
func function() -> Self.CustomAssociatedType
```
```javascript
// From
var getSetVar: any Swift.Equatable { get set }

// To
var getSetVar: Self.AnotherAssociatedType { get set }
```
```javascript
// From
var getVar: any Swift.Equatable { get }

// To
var getVar: Self.CustomAssociatedType { get }
```
#### 😶‍🌫️ Removed
```javascript
typealias CustomAssociatedType = Swift.Equatable
```
### `ReferencePackage.CustomStruct`
#### ❇️ Added
```javascript
@available(macOS, unavailable, message: "Unavailable on macOS") public struct NestedStruct
{
  @available(*, deprecated, renamed: "nestedVar") public let nestedLet: Swift.String
  @available(swift 5.9) public let nestedVar: Swift.String
}
```
```javascript
public typealias AnotherAssociatedType = Swift.Double
```
```javascript
public typealias CustomAssociatedType = Swift.Int
```
```javascript
public typealias Iterator = Swift.Array<ReferencePackage.CustomStruct<T>.AnotherAssociatedType>
```
```javascript
public typealias ParentType = Swift.Double
```
#### 🔀 Changed
```javascript
// From
@discardableResult public func function() -> any Swift.Equatable

// To
@discardableResult public func function() -> Swift.Int
```
```javascript
// From
public var getSetVar: any Swift.Equatable

// To
public var getSetVar: Swift.Double
```
```javascript
// From
public var getVar: any Swift.Equatable

// To
public var getVar: Swift.Int
```
### `ReferencePackage.OpenSpiConformingClass`
#### ❇️ Added
```javascript
@_spi(SystemProgrammingInterface) public typealias AnotherAssociatedType = T
```
```javascript
@_spi(SystemProgrammingInterface) public typealias Iterator = Swift.Array<Swift.Double>
```
```javascript
@_spi(SystemProgrammingInterface) public typealias ParentType = Swift.Double
```
#### 🔀 Changed
```javascript
// From
@_spi(SystemProgrammingInterface) @inlinable public func function() -> ReferencePackage.OpenSpiConformingClass.CustomAssociatedType

// To
@_spi(SystemProgrammingInterface) @inlinable public func function() -> T
```
```javascript
// From
@_spi(SystemProgrammingInterface) public init(getSetVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType, getVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType)

// To
@_spi(SystemProgrammingInterface) public init(getSetVar: T, getVar: T)
```
```javascript
// From
@_spi(SystemProgrammingInterface) public typealias CustomAssociatedType = any Swift.Equatable

// To
@_spi(SystemProgrammingInterface) public typealias CustomAssociatedType = T
```
```javascript
// From
@_spi(SystemProgrammingInterface) public var getSetVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType

// To
@_spi(SystemProgrammingInterface) public var getSetVar: T
```
```javascript
// From
@_spi(SystemProgrammingInterface) public var getVar: ReferencePackage.OpenSpiConformingClass.CustomAssociatedType

// To
@_spi(SystemProgrammingInterface) public var getVar: T
```
### `ReferencePackage.RawValueEnum`
#### ❇️ Added
```javascript
extension ReferencePackage.RawValueEnum: Swift.Equatable
```
```javascript
extension ReferencePackage.RawValueEnum: Swift.Hashable
```
```javascript
extension ReferencePackage.RawValueEnum: Swift.RawRepresentable
```
### `Swift.Array`
#### ❇️ Added
```javascript
extension Swift.Array
{
  public subscript(safe index: Swift.Int) -> Element? { get }
}
```

---
**Analyzed targets:** ReferencePackage
