/* ----------------------------------------------------------------
 * :: :  M  E  T  A  V  E  R  S  E  :                            ::
 * ----------------------------------------------------------------
 * This software is Licensed under the terms of the Apache License,
 * version 2.0 (the "Apache License") with the following additional
 * modification; you may not use this file except within compliance
 * of the Apache License and the following modification made to it.
 * Section 6. Trademarks. is deleted and replaced with:
 *
 * Trademarks. This License does not grant permission to use any of
 * its trade names, trademarks, service marks, or the product names
 * of this Licensor or its affiliates, except as required to comply
 * with Section 4(c.) of this License, and to reproduce the content
 * of the NOTICE file.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND without even an
 * implied warranty of MERCHANTABILITY, or FITNESS FOR A PARTICULAR
 * PURPOSE. See the Apache License for more details.
 *
 * You should have received a copy for this software license of the
 * Apache License along with this program; or, if not, please write
 * to the Free Software Foundation Inc., with the following address
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 *         Copyright (C) 2024 Wabi Foundation. All Rights Reserved.
 * ----------------------------------------------------------------
 *  . x x x . o o o . x x x . : : : .    o  x  o    . : : : .
 * ---------------------------------------------------------------- */

import Realm
import Realm.Private

/// Get a pointer to the given property's ivar on the object. This is similar to
/// object_getIvar() but returns a pointer to the value rather than the value.
@_transparent
private func ptr(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutableRawPointer
{
  Unmanaged.passUnretained(obj).toOpaque().advanced(by: property.swiftIvar)
}

// MARK: - Legacy Property Accessors

class ListAccessor<Element: RealmCollectionValue>: RLMManagedPropertyAccessor
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> List<Element>
  {
    ptr(property, obj).assumingMemoryBound(to: List<Element>.self).pointee
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent)._rlmCollection = RLMManagedArray(parent: parent, property: property)
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).rlmArray.setParent(parent, property: property)
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent)
  }

  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).assign(value)
  }
}

class SetAccessor<Element: RealmCollectionValue>: RLMManagedPropertyAccessor
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> MutableSet<Element>
  {
    ptr(property, obj).assumingMemoryBound(to: MutableSet<Element>.self).pointee
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent)._rlmCollection = RLMManagedSet(parent: parent, property: property)
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).rlmSet.setParent(parent, property: property)
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent)
  }

  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).assign(value)
  }
}

class MapAccessor<Key: _MapKey, Value: RealmCollectionValue>: RLMManagedPropertyAccessor
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> Map<Key, Value>
  {
    ptr(property, obj).assumingMemoryBound(to: Map<Key, Value>.self).pointee
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent)._rlmCollection = RLMManagedDictionary(parent: parent, property: property)
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).rlmDictionary.setParent(parent, property: property)
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent)
  }

  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).assign(value)
  }
}

class LinkingObjectsAccessor<Element: ObjectBase>: RLMManagedPropertyAccessor
  where Element: RealmCollectionValue
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutablePointer<LinkingObjects<Element>>
  {
    ptr(property, obj).assumingMemoryBound(to: LinkingObjects<Element>.self)
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).pointee.handle =
      RLMLinkingObjectsHandle(object: parent, property: property)
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    if parent.lastAccessedNames != nil
    {
      bound(property, parent).pointee.handle = RLMLinkingObjectsHandle(object: parent, property: property)
    }
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent).pointee
  }
}

@available(*, deprecated)
class RealmOptionalAccessor<Value: RealmOptionalType>: RLMManagedPropertyAccessor
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> RealmOptional<Value>
  {
    ptr(property, obj).assumingMemoryBound(to: RealmOptional<Value>.self).pointee
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    RLMInitializeManagedSwiftValueStorage(bound(property, parent), parent, property)
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    RLMInitializeUnmanagedSwiftValueStorage(bound(property, parent), parent, property)
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    let value = bound(property, parent).value
    return value._rlmObjcValue
  }

  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).value = Value._rlmFromObjc(value)
  }
}

class RealmPropertyAccessor<Value: RealmPropertyType>: RLMManagedPropertyAccessor
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> RealmProperty<Value>
  {
    ptr(property, obj).assumingMemoryBound(to: RealmProperty<Value>.self).pointee
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    RLMInitializeManagedSwiftValueStorage(bound(property, parent), parent, property)
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    RLMInitializeUnmanagedSwiftValueStorage(bound(property, parent), parent, property)
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent).value._rlmObjcValue
  }

  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).value = Value._rlmFromObjc(value)!
  }
}

// MARK: - Modern Property Accessors

class PersistedPropertyAccessor<T: _Persistable>: RLMManagedPropertyAccessor
{
  fileprivate static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutablePointer<Persisted<T>>
  {
    ptr(property, obj).assumingMemoryBound(to: Persisted<T>.self)
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).pointee.initialize(parent, key: PropertyKey(property.index))
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).pointee.observe(parent, property: property)
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent).pointee.get(parent)
  }

  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    guard let v = T._rlmFromObjc(value)
    else
    {
      throwRealmException("Could not convert value '\(value)' to type '\(T.self)'.")
    }
    bound(property, parent).pointee.set(parent, value: v)
  }
}

class PersistedListAccessor<Element: RealmCollectionValue & _Persistable>: PersistedPropertyAccessor<List<Element>>
{
  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).pointee.get(parent).assign(value)
  }

  /// When promoting an existing object to managed we want to promote the existing
  /// Swift collection object if it exists
  @objc override class func promote(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    let key = PropertyKey(property.index)
    if let existing = bound(property, parent).pointee.initializeCollection(parent, key: key)
    {
      existing._rlmCollection = RLMGetSwiftPropertyArray(parent, key)
    }
  }
}

class PersistedSetAccessor<Element: RealmCollectionValue & _Persistable>: PersistedPropertyAccessor<MutableSet<Element>>
{
  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).pointee.get(parent).assign(value)
  }

  @objc override class func promote(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    let key = PropertyKey(property.index)
    if let existing = bound(property, parent).pointee.initializeCollection(parent, key: key)
    {
      existing._rlmCollection = RLMGetSwiftPropertyArray(parent, key)
    }
  }
}

class PersistedMapAccessor<Key: _MapKey, Value: RealmCollectionValue & _Persistable>: PersistedPropertyAccessor<Map<Key, Value>>
{
  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    bound(property, parent).pointee.get(parent).assign(value)
  }

  @objc override class func promote(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    let key = PropertyKey(property.index)
    if let existing = bound(property, parent).pointee.initializeCollection(parent, key: key)
    {
      existing._rlmCollection = RLMGetSwiftPropertyMap(parent, PropertyKey(property.index))
    }
  }
}

class PersistedLinkingObjectsAccessor<Element: ObjectBase & RealmCollectionValue & _Persistable>: RLMManagedPropertyAccessor
{
  private static func bound(_ property: RLMProperty, _ obj: RLMObjectBase) -> UnsafeMutablePointer<Persisted<LinkingObjects<Element>>>
  {
    ptr(property, obj).assumingMemoryBound(to: Persisted<LinkingObjects<Element>>.self)
  }

  @objc override class func initialize(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    bound(property, parent).pointee.initialize(parent, key: PropertyKey(property.index))
  }

  @objc override class func observe(_ property: RLMProperty, on parent: RLMObjectBase)
  {
    if parent.lastAccessedNames != nil
    {
      bound(property, parent).pointee.observe(parent, property: property)
    }
  }

  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent).pointee.get(parent)
  }
}

/// Dynamic getters return the Swift type for Collections, and the obj-c type
/// for enums and AnyRealmValue. This difference is probably a mistake but it's
/// a breaking change to adjust.
class BridgedPersistedPropertyAccessor<T: _Persistable>: PersistedPropertyAccessor<T>
{
  @objc override class func get(_ property: RLMProperty, on parent: RLMObjectBase) -> Any
  {
    bound(property, parent).pointee.get(parent)._rlmObjcValue
  }
}

class CustomPersistablePropertyAccessor<T: _Persistable>: BridgedPersistedPropertyAccessor<T>
{
  @objc override class func set(_ property: RLMProperty, on parent: RLMObjectBase, to value: Any)
  {
    if coerceToNil(value) == nil
    {
      super.set(property, on: parent, to: T._rlmDefaultValue())
    }
    else
    {
      super.set(property, on: parent, to: value)
    }
  }
}
