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

extension Object: SchemaDiscoverable, _PersistableInsideOptional, _DefaultConstructible
{
  public typealias PersistedType = Object
  public static var _rlmType: PropertyType { .object }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    if !prop.optional, !prop.collection
    {
      throwRealmException("Object property '\(prop.name)' must be marked as optional.")
    }
    if prop.optional, prop.array
    {
      throwRealmException("List<\(className())> property '\(prop.name)' must not be marked as optional.")
    }
    if prop.optional, prop.set
    {
      throwRealmException("MutableSet<\(className())> property '\(prop.name)' must not be marked as optional.")
    }
    if !prop.optional, prop.dictionary
    {
      throwRealmException("Map<String, \(className())> property '\(prop.name)' must be marked as optional.")
    }
    prop.objectClassName = className()
  }

  public static func _rlmGetProperty(_: ObjectBase, _: UInt16) -> Self
  {
    fatalError("Non-optional Object properties are not allowed.")
  }

  public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self?
  {
//        FIXME: gives Assertion failed: (LocalSelf && "no local self metadata"), function getLocalSelfMetadata, file /src/swift-source/swift/lib/IRGen/GenHeap.cpp, line 1686.
//        return RLMGetSwiftPropertyObject(obj, key).map(dynamicBridgeCast)
    if let value = RLMGetSwiftPropertyObject(obj, key)
    {
      return (value as! Self)
    }
    return nil
  }

  public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: Object)
  {
    RLMSetSwiftPropertyObject(obj, key, value)
  }
}

extension EmbeddedObject: SchemaDiscoverable, _PersistableInsideOptional, _DefaultConstructible
{
  public typealias PersistedType = EmbeddedObject
  public static var _rlmType: PropertyType { .object }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    Object._rlmPopulateProperty(prop)
    prop.objectClassName = className()
  }

  public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self
  {
    if let value = RLMGetSwiftPropertyObject(obj, key)
    {
      return value as! Self
    }
    return Self()
  }

  public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: UInt16) -> Self?
  {
    if let value = RLMGetSwiftPropertyObject(obj, key)
    {
      return (value as! Self)
    }
    return nil
  }

  public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: EmbeddedObject)
  {
    RLMSetSwiftPropertyObject(obj, key, value)
  }
}

extension List: _RealmSchemaDiscoverable, SchemaDiscoverable where Element: _RealmSchemaDiscoverable
{
  public static var _rlmType: PropertyType { Element._rlmType }
  public static var _rlmOptional: Bool { Element._rlmOptional }
  public static var _rlmRequireObjc: Bool { false }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    prop.array = true
    prop.swiftAccessor = ListAccessor<Element>.self
    Element._rlmPopulateProperty(prop)
  }
}

extension List: _HasPersistedType, _Persistable, _DefaultConstructible where Element: _Persistable
{
  public typealias PersistedType = List
  public static var _rlmRequiresCaching: Bool { true }

  public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self
  {
    Self(collection: RLMGetSwiftPropertyArray(obj, key))
  }

  public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: List)
  {
    let array = RLMGetSwiftPropertyArray(obj, key)
    if array.isEqual(value.rlmArray) { return }
    array.removeAllObjects()
    array.addObjects(value.rlmArray)
  }

  public static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    prop.swiftAccessor = PersistedListAccessor<Element>.self
  }
}

extension MutableSet: _RealmSchemaDiscoverable, SchemaDiscoverable where Element: _RealmSchemaDiscoverable
{
  public static var _rlmType: PropertyType { Element._rlmType }
  public static var _rlmOptional: Bool { Element._rlmOptional }
  public static var _rlmRequireObjc: Bool { false }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    prop.set = true
    prop.swiftAccessor = SetAccessor<Element>.self
    Element._rlmPopulateProperty(prop)
  }
}

extension MutableSet: _HasPersistedType, _Persistable, _DefaultConstructible where Element: _Persistable
{
  public typealias PersistedType = MutableSet
  public static var _rlmRequiresCaching: Bool { true }

  public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self
  {
    Self(collection: RLMGetSwiftPropertySet(obj, key))
  }

  public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: MutableSet)
  {
    let set = RLMGetSwiftPropertySet(obj, key)
    if set.isEqual(value.rlmSet) { return }
    set.removeAllObjects()
    set.addObjects(value.rlmSet)
  }

  public static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    prop.swiftAccessor = PersistedSetAccessor<Element>.self
  }
}

extension Map: _RealmSchemaDiscoverable, SchemaDiscoverable where Value: _RealmSchemaDiscoverable
{
  public static var _rlmType: PropertyType { Value._rlmType }
  public static var _rlmOptional: Bool { Value._rlmOptional }
  public static var _rlmRequireObjc: Bool { false }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    prop.dictionary = true
    prop.swiftAccessor = MapAccessor<Key, Value>.self
    prop.dictionaryKeyType = Key._rlmType
    Value._rlmPopulateProperty(prop)
  }
}

extension Map: _HasPersistedType, _Persistable, _DefaultConstructible where Value: _Persistable
{
  public typealias PersistedType = Map
  public static var _rlmRequiresCaching: Bool { true }

  public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Self
  {
    Self(objc: RLMGetSwiftPropertyMap(obj, key))
  }

  public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: Map)
  {
    let map = RLMGetSwiftPropertyMap(obj, key)
    if map.isEqual(value.rlmDictionary) { return }
    map.removeAllObjects()
    map.addEntries(fromDictionary: value.rlmDictionary)
  }

  public static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    prop.swiftAccessor = PersistedMapAccessor<Key, Value>.self
  }
}

extension LinkingObjects: SchemaDiscoverable
{
  public static var _rlmType: PropertyType { .linkingObjects }
  public static var _rlmRequireObjc: Bool { false }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    prop.array = true
    prop.objectClassName = Element.className()
    prop.swiftAccessor = LinkingObjectsAccessor<Element>.self
    if prop.linkOriginPropertyName == nil
    {
      throwRealmException("LinkingObjects<\(prop.objectClassName!)> property '\(prop.name)' must set the origin property name with @Persisted(originProperty: \"name\").")
    }
  }

  public func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    prop.linkOriginPropertyName = propertyName
  }
}

@available(*, deprecated)
extension RealmOptional: SchemaDiscoverable, _RealmSchemaDiscoverable where Value: _RealmSchemaDiscoverable
{
  public static var _rlmType: PropertyType { Value._rlmType }
  public static var _rlmOptional: Bool { true }
  public static var _rlmRequireObjc: Bool { false }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    Value._rlmPopulateProperty(prop)
    prop.swiftAccessor = RealmOptionalAccessor<Value>.self
  }
}

extension LinkingObjects: _HasPersistedType, _Persistable where Element: _Persistable
{
  public typealias PersistedType = Self
  public static func _rlmDefaultValue() -> Self
  {
    fatalError("LinkingObjects properties must set the origin property name")
  }

  public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> LinkingObjects
  {
    let prop = RLMObjectBaseObjectSchema(obj)!.computedProperties[Int(key)]
    return Self(propertyName: prop.name, handle: RLMLinkingObjectsHandle(object: obj, property: prop))
  }

  public static func _rlmSetProperty(_: ObjectBase, _: UInt16, _: LinkingObjects)
  {
    fatalError("LinkingObjects properties are read-only")
  }

  public static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    prop.swiftAccessor = PersistedLinkingObjectsAccessor<Element>.self
  }
}

extension Optional: SchemaDiscoverable, _RealmSchemaDiscoverable where Wrapped: _RealmSchemaDiscoverable
{
  public static var _rlmType: PropertyType { Wrapped._rlmType }
  public static var _rlmOptional: Bool { true }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    Wrapped._rlmPopulateProperty(prop)
  }
}

extension Optional: _HasPersistedType where Wrapped: _HasPersistedType
{
  public typealias PersistedType = Wrapped.PersistedType?
}

extension Optional: _Persistable where Wrapped: _PersistableInsideOptional
{
  public static func _rlmDefaultValue() -> Self
  {
    .none
  }

  public static func _rlmGetProperty(_ obj: ObjectBase, _ key: UInt16) -> Wrapped?
  {
    Wrapped._rlmGetPropertyOptional(obj, key)
  }

  public static func _rlmSetProperty(_ obj: ObjectBase, _ key: UInt16, _ value: Wrapped?)
  {
    if let value
    {
      Wrapped._rlmSetProperty(obj, key, value)
    }
    else
    {
      RLMSetSwiftPropertyNil(obj, key)
    }
  }

  public static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    Wrapped._rlmSetAccessor(prop)
  }
}

extension Optional: _PrimaryKey where Wrapped: _Persistable, Wrapped.PersistedType: _PrimaryKey {}
extension Optional: _Indexable where Wrapped: _Persistable, Wrapped.PersistedType: _Indexable {}

extension RealmProperty: _RealmSchemaDiscoverable, SchemaDiscoverable
{
  public static var _rlmType: PropertyType { Value._rlmType }
  public static var _rlmOptional: Bool { Value._rlmOptional }
  public static var _rlmRequireObjc: Bool { false }
  public static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    Value._rlmPopulateProperty(prop)
    prop.swiftAccessor = RealmPropertyAccessor<Value>.self
  }
}

public extension RawRepresentable where RawValue: _RealmSchemaDiscoverable
{
  static var _rlmType: PropertyType { RawValue._rlmType }
  static var _rlmOptional: Bool { RawValue._rlmOptional }
  static var _rlmRequireObjc: Bool { false }
  func _rlmPopulateProperty(_: RLMProperty) {}
  static func _rlmPopulateProperty(_ prop: RLMProperty)
  {
    RawValue._rlmPopulateProperty(prop)
  }
}

public extension RawRepresentable where Self: _PersistableInsideOptional, RawValue: _PersistableInsideOptional
{
  typealias PersistedType = RawValue
  static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Self
  {
    Self(rawValue: RawValue._rlmGetProperty(obj, key))!
  }

  static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self?
  {
    RawValue._rlmGetPropertyOptional(obj, key).flatMap(Self.init)
  }

  static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Self)
  {
    RawValue._rlmSetProperty(obj, key, value.rawValue)
  }

  static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    if prop.optional
    {
      prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self?>.self
    }
    else
    {
      prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self>.self
    }
  }
}
