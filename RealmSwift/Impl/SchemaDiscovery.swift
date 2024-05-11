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

import Foundation
import Realm
import Realm.Private

/// A type which we can get the runtime schema information from
public protocol _RealmSchemaDiscoverable
{
  /// The Realm property type associated with this type
  static var _rlmType: PropertyType { get }
  static var _rlmOptional: Bool { get }
  /// Does this type require @objc for legacy declarations? Not used for modern
  /// declarations as no types use @objc.
  static var _rlmRequireObjc: Bool { get }

  /// Set any fields of the property applicable to this type other than type/optional.
  /// There are both static and non-static versions of this function because
  /// some times need data from an instance (e.g. LinkingObjects, where the
  /// source property name is runtime data and not part of the type), while
  /// wrappers like Optional need to be able to recur to the wrapped type
  /// without creating an instance of that.
  func _rlmPopulateProperty(_ prop: RLMProperty)
  static func _rlmPopulateProperty(_ prop: RLMProperty)
}

extension RLMObjectBase
{
  /// Allow client code to generate properties (ie. via Swift Macros)
  @_spi(RealmSwiftPrivate)
  @objc open class func _customRealmProperties() -> [RLMProperty]?
  {
    nil
  }
}

protocol SchemaDiscoverable: _RealmSchemaDiscoverable {}
extension SchemaDiscoverable
{
  public static var _rlmOptional: Bool { false }
  public static var _rlmRequireObjc: Bool { true }
  public func _rlmPopulateProperty(_: RLMProperty) {}
  public static func _rlmPopulateProperty(_: RLMProperty) {}
}

extension RLMProperty
{
  convenience init(name: String, value: _RealmSchemaDiscoverable)
  {
    let valueType = Swift.type(of: value)
    self.init()
    self.name = name
    type = valueType._rlmType
    optional = valueType._rlmOptional
    value._rlmPopulateProperty(self)
    valueType._rlmPopulateProperty(self)
    if valueType._rlmRequireObjc
    {
      updateAccessors()
    }
  }

  /// Exposed for Macros.
  /// Important: Keep args in same order & default value as `@Persisted` property wrapper
  @_spi(RealmSwiftPrivate)
  public convenience init<O: ObjectBase, V: _Persistable>(
    name: String,
    objectType _: O.Type,
    valueType _: V.Type,
    indexed: Bool = false,
    primaryKey: Bool = false,
    originProperty: String? = nil
  )
  {
    self.init()
    self.name = name
    type = V._rlmType
    optional = V._rlmOptional
    self.indexed = primaryKey || indexed
    isPrimary = primaryKey
    linkOriginPropertyName = originProperty
    V._rlmPopulateProperty(self)
    V._rlmSetAccessor(self)
    swiftIvar = ivar_getOffset(class_getInstanceVariable(O.self, "_" + name)!)
  }
}

private func getModernProperties(_ object: ObjectBase) -> [RLMProperty]
{
  let columnNames: [String: String] = type(of: object).propertiesMapping()
  return Mirror(reflecting: object).children.compactMap
  { prop in
    guard let label = prop.label else { return nil }
    guard let value = prop.value as? DiscoverablePersistedProperty
    else
    {
      return nil
    }
    let property = RLMProperty(name: label, value: value)
    property.swiftIvar = ivar_getOffset(class_getInstanceVariable(type(of: object), label)!)
    property.columnName = columnNames[property.name]
    return property
  }
}

/// If the property is a storage property for a lazy Swift property, return
/// the base property name (e.g. `foo.storage` becomes `foo`). Otherwise, nil.
private func baseName(forLazySwiftProperty name: String) -> String?
{
  // A Swift lazy var shows up as two separate children on the reflection tree:
  // one named 'x', and another that is optional and is named "$__lazy_storage_$_propName"
  if let storageRange = name.range(of: "$__lazy_storage_$_", options: [.anchored])
  {
    return String(name[storageRange.upperBound...])
  }
  return nil
}

private func getLegacyProperties(_ object: ObjectBase, _ cls: ObjectBase.Type) -> [RLMProperty]
{
  let indexedProperties: Set<String>
  let ignoredPropNames: Set<String>
  let columnNames: [String: String] = type(of: object).propertiesMapping()
  // FIXME: ignored properties on EmbeddedObject appear to not be supported?
  if let realmObject = object as? Object
  {
    indexedProperties = Set(type(of: realmObject).indexedProperties())
    ignoredPropNames = Set(type(of: realmObject).ignoredProperties())
  }
  else
  {
    indexedProperties = Set()
    ignoredPropNames = Set()
  }
  return Mirror(reflecting: object).children.filter
  { (prop: Mirror.Child) -> Bool in
    guard let label = prop.label else { return false }
    if ignoredPropNames.contains(label)
    {
      return false
    }
    if let lazyBaseName = baseName(forLazySwiftProperty: label)
    {
      if ignoredPropNames.contains(lazyBaseName)
      {
        return false
      }
      throwRealmException("Lazy managed property '\(lazyBaseName)' is not allowed on a Realm Swift object"
        + " class. Either add the property to the ignored properties list or make it non-lazy.")
    }
    return true
  }.compactMap
  { prop in
    guard let label = prop.label else { return nil }
    var rawValue = prop.value
    if let value = rawValue as? RealmEnum
    {
      rawValue = value._rlmObjcValue
    }

    guard let value = rawValue as? _RealmSchemaDiscoverable
    else
    {
      if class_getProperty(cls, label) != nil
      {
        throwRealmException("Property \(cls).\(label) is declared as \(type(of: prop.value)), which is not a supported managed Object property type. If it is not supposed to be a managed property, either add it to `ignoredProperties()` or do not declare it as `@objc dynamic`. See https://www.mongodb.com/docs/realm-sdks/swift/latest/Classes/Object.html for more information.")
      }
      if prop.value as? RealmOptionalProtocol != nil
      {
        throwRealmException("Property \(cls).\(label) has unsupported RealmOptional type \(type(of: prop.value)). Extending RealmOptionalType with custom types is not currently supported. ")
      }
      return nil
    }

    RLMValidateSwiftPropertyName(label)
    let valueType = type(of: value)

    let property = RLMProperty(name: label, value: value)
    property.indexed = indexedProperties.contains(property.name)
    property.columnName = columnNames[property.name]

    if let objcProp = class_getProperty(cls, label)
    {
      var count: UInt32 = 0
      let attrs = property_copyAttributeList(objcProp, &count)!
      defer
      {
        free(attrs)
      }
      var computed = true
      for i in 0 ..< Int(count)
      {
        let attr = attrs[i]
        switch attr.name[0]
        {
          case Int8(UInt8(ascii: "R")): // Read only
            return nil
          case Int8(UInt8(ascii: "V")): // Ivar name
            computed = false
          case Int8(UInt8(ascii: "G")): // Getter name
            property.getterName = String(cString: attr.value)
          case Int8(UInt8(ascii: "S")): // Setter name
            property.setterName = String(cString: attr.value)
          default:
            break
        }
      }

      // If there's no ivar name and no ivar with the same name as
      // the property then this is a computed property and we should
      // implicitly ignore it
      if computed, class_getInstanceVariable(cls, label) == nil
      {
        return nil
      }
    }
    else if valueType._rlmRequireObjc
    {
      // Implicitly ignore non-@objc dynamic properties
      return nil
    }
    else
    {
      property.swiftIvar = ivar_getOffset(class_getInstanceVariable(cls, label)!)
    }

    property.isLegacy = true
    property.updateAccessors()
    return property
  }
}

private func getProperties(_ cls: RLMObjectBase.Type) -> [RLMProperty]
{
  if let props = cls._customRealmProperties()
  {
    return props
  }
  // Check for any modern properties and only scan for legacy properties if
  // none are found.
  let object = cls.init()
  let props = getModernProperties(object)
  if !props.isEmpty
  {
    return props
  }
  return getLegacyProperties(object, cls)
}

class ObjectUtil
{
  private static let runOnce: Void = {
    RLMSetSwiftBridgeCallback
    { (value: Any) -> Any? in
      // `as AnyObject` required on iOS <= 13; it will compile but silently
      // fail to cast otherwise
      if let value = value as AnyObject as? _ObjcBridgeable
      {
        return value._rlmObjcValue
      }
      return nil
    }
  }()

  class func getSwiftProperties(_ cls: RLMObjectBase.Type) -> [RLMProperty]
  {
    _ = ObjectUtil.runOnce
    return getProperties(cls)
  }
}
