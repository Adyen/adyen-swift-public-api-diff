# 👀 11 public changes detected
_Comparing `/.../.../UpdatedPackage` to `/.../.../ReferencePackage`_

---
## `ReferencePackage`
#### 🔀 Changed
```javascript
// From
public protocol CustomProtocol

// To
public protocol CustomProtocol<Self.CustomAssociatedType : Equatable>

/**
Changes:
- Added generic signature `<Self.CustomAssociatedType : Equatable>`
*/
```
```javascript
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
```javascript
public associatedtype CustomAssociatedType
```
#### 🔀 Changed
```javascript
// From
public func function<Self where Self : ReferencePackage.CustomProtocol>() -> any Self.CustomAssociatedType

// To
public func function<Self where Self : ReferencePackage.CustomProtocol>() -> Self.CustomAssociatedType
```
```javascript
// From
public var getSetVar: any Self.CustomAssociatedType { get set }

// To
public var getSetVar: Self.CustomAssociatedType { get set }
```
```javascript
// From
public var getVar: any Self.CustomAssociatedType { get }

// To
public var getVar: Self.CustomAssociatedType { get }
```
#### 😶‍🌫️ Removed
```javascript
public typealias CustomAssociatedType = Equatable
```
### `CustomStruct`
#### ❇️ Added
```javascript
public typealias CustomAssociatedType = Int
```
#### 🔀 Changed
```javascript
// From
@discardableResult public func function() -> any Equatable

// To
@discardableResult public func function<T where T : Strideable>() -> Int

/**
Changes:
- Added generic signature `<T where T : Strideable>`
*/
```
```javascript
// From
public var getSetVar: any Equatable { get set }

// To
public var getSetVar: Int { get set }
```
```javascript
// From
public var getVar: any Equatable { get set }

// To
public var getVar: Int { get set }
```

---
**Analyzed targets:** ReferencePackage
