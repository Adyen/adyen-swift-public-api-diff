# 👀 11 public changes detected
_Comparing `/.../.../UpdatedPackage` to `/.../.../ReferencePackage`_

---
## `ReferencePackage`
#### 🔀 Changed
```swift
// From
public protocol CustomProtocol

// To
public protocol CustomProtocol<Self.CustomAssociatedType : Equatable>

/**
Changes:
- Added generic signature `<Self.CustomAssociatedType : Equatable>`
*/
```
```swift
// From
public struct CustomStruct : CustomProtocol

// To
public struct CustomStruct<T where T : Strideable> : CustomProtocol

/**
Changes:
- Added generic signature `<T where T : Strideable>`
*/
```
### `CustomProtocol`
#### ❇️ Added
```swift
public associatedtype CustomAssociatedType
```
#### 🔀 Changed
```swift
// From
public func function<Self where Self : ReferencePackage.CustomProtocol>() -> any Self.CustomAssociatedType

// To
public func function<Self where Self : ReferencePackage.CustomProtocol>() -> Self.CustomAssociatedType
```
```swift
// From
public var getSetVar: any Self.CustomAssociatedType { get set }

// To
public var getSetVar: Self.CustomAssociatedType { get set }
```
```swift
// From
public var getVar: any Self.CustomAssociatedType { get }

// To
public var getVar: Self.CustomAssociatedType { get }
```
#### 😶‍🌫️ Removed
```swift
public typealias CustomAssociatedType = Equatable
```
### `CustomStruct`
#### ❇️ Added
```swift
public typealias CustomAssociatedType = Int
```
#### 🔀 Changed
```swift
// From
@discardableResult public func function() -> any Equatable

// To
@discardableResult public func function<T where T : Strideable>() -> Int

/**
Changes:
- Added generic signature `<T where T : Strideable>`
*/
```
```swift
// From
public var getSetVar: any Equatable { get set }

// To
public var getSetVar: Int { get set }
```
```swift
// From
public var getVar: any Equatable { get set }

// To
public var getVar: Int { get set }
```

---
**Analyzed targets:** ReferencePackage
