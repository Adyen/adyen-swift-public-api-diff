# 👀 54 public changes detected
_Comparing `new_private` to `old_private`_

---
## `ReferencePackage`
#### ❇️ Added
```javascript
public enum RawValueEnum: Swift.String, Swift.Equatable, Swift.Hashable, Swift.RawRepresentable {
  case one
  case two
  public init?(rawValue: Swift.String)
  public typealias RawValue = Swift.String
  public var rawValue: Swift.String { get }
}

```
```javascript
public protocol ParentProtocol {
  associatedtype ParentType: Swift.Equatable where Self.ParentType == Self.Iterator.Element
  associatedtype Iterator: Swift.Collection
}

```
```javascript
public protocol ParentProtocol<ParentType> {
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
#### 🔀 Changed
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
public struct NestedStructInExtension {
  public let string: Swift.String { get }
  public init(string: Swift.String = "Hello")
}

```
#### 🔀 Changed
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
#### 😶‍🌫️ Removed
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
#### 🔀 Changed
```javascript
// From
func function() -> any Swift.Equatable

// To
func function() -> Self.CustomAssociatedType

/**
Changes:
- Changed return type from `any Swift.Equatable` to `Self.CustomAssociatedType`
*/
```
```javascript
// From
var getSetVar: any Swift.Equatable { get set }

// To
var getSetVar: Self.AnotherAssociatedType { get set }

/**
Changes:
- Changed type from `any Swift.Equatable` to `Self.AnotherAssociatedType`
*/
```
```javascript
// From
var getVar: any Swift.Equatable { get }

// To
var getVar: Self.CustomAssociatedType { get }

/**
Changes:
- Changed type from `any Swift.Equatable` to `Self.CustomAssociatedType`
*/
```
#### 😶‍🌫️ Removed
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
#### 🔀 Changed
```javascript
// From
@discardableResult
public func function() -> any Swift.Equatable

// To
@discardableResult
public func function() -> Swift.Int

/**
Changes:
- Changed return type from `any Swift.Equatable` to `Swift.Int`
*/
```
```javascript
// From
public var getSetVar: any Swift.Equatable

// To
public var getSetVar: Swift.Double

/**
Changes:
- Changed type from `any Swift.Equatable` to `Swift.Double`
*/
```
```javascript
// From
public var getVar: any Swift.Equatable

// To
public var getVar: Swift.Int

/**
Changes:
- Changed type from `any Swift.Equatable` to `Swift.Int`
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
#### 🔀 Changed
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
- Changed return type from `ReferencePackage.OpenSpiConformingClass.CustomAssociatedType` to `T`
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
- Changed assignment from `any Swift.Equatable` to `T`
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
- Changed type from `ReferencePackage.OpenSpiConformingClass.CustomAssociatedType` to `T`
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
- Changed type from `ReferencePackage.OpenSpiConformingClass.CustomAssociatedType` to `T`
*/
```

---
**Analyzed targets:** ReferencePackage
