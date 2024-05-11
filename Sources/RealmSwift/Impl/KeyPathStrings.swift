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
import Realm.Private

/**
 Gets the components of a given key path as a string.

 - warning: Objects that declare properties with the old `@objc dynamic` syntax are not fully supported
 by this function, and it is recommended that you use `@Persisted` to declare your properties if you wish to use
 this function to its full benefit.

 Example:
 ```
 let name = ObjectBase._name(for: \Person.dogs[0].name) // "dogs.name"
 // Note that the above KeyPath expression is only supported with properties declared
 // with `@Persisted`.
 let nested = ObjectBase._name(for: \Person.address.city.zip) // "address.city.zip"
 ```
 */
public func _name(for keyPath: PartialKeyPath<some ObjectBase>) -> String
{
  name(for: keyPath)
}

/**
 Gets the components of a given key path as a string.

 - warning: Objects that declare properties with the old `@objc dynamic` syntax are not fully supported
 by this function, and it is recommended that you use `@Persisted` to declare your properties if you wish to use
 this function to its full benefit.

 Example:
 ```
 let name = PersonProjection._name(for: \PersonProjection.dogs[0].name) // "dogs.name"
 // Note that the above KeyPath expression is only supported with properties declared
 // with `@Persisted`.
 let nested = ObjectBase._name(for: \Person.address.city.zip) // "address.city.zip"
 ```
 */
public func _name(for keyPath: PartialKeyPath<some Projection<some ObjectBase>>) -> String
{
  name(for: keyPath)
}

private func name<T: KeypathRecorder>(for keyPath: PartialKeyPath<T>) -> String
{
  if let name = keyPath._kvcKeyPathString
  {
    return name
  }
  let names = NSMutableArray()
  let value = T.keyPathRecorder(with: names)[keyPath: keyPath]
  if let collection = value as? PropertyNameConvertible,
     let propertyInfo = collection.propertyInformation, propertyInfo.isLegacy
  {
    names.add(propertyInfo.key)
  }

  if let storage = value as? RLMSwiftValueStorage
  {
    names.add(RLMSwiftValueStorageGetPropertyName(storage))
  }
  return names.componentsJoined(by: ".")
}

/// Create a valid element for a collection, as a keypath recorder if that type supports it.
func elementKeyPathRecorder<T: RealmCollectionValue>(
  for type: T.Type, with lastAccessedNames: NSMutableArray
) -> T
{
  if let type = type as? KeypathRecorder.Type
  {
    return type.keyPathRecorder(with: lastAccessedNames) as! T
  }
  return T._rlmDefaultValue()
}

// MARK: - Implementation

/// Protocol which allows a collection to produce its property name
protocol PropertyNameConvertible
{
  /// A mutable array referenced from the enclosing parent that contains the last accessed property names.
  var lastAccessedNames: NSMutableArray? { get set }
  /// `key` is the property name for this collection.
  /// `isLegacy` will be true if the property is declared with old property syntax.
  var propertyInformation: (key: String, isLegacy: Bool)? { get }
}

protocol KeypathRecorder
{
  /// Return an instance of Self which is initialized for keypath recording
  /// using the given target array.
  static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self
}

extension Optional: KeypathRecorder where Wrapped: KeypathRecorder
{
  static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self
  {
    Wrapped.keyPathRecorder(with: lastAccessedNames)
  }
}

extension ObjectBase: KeypathRecorder
{
  static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self
  {
    let obj = Self()
    obj.lastAccessedNames = lastAccessedNames
    let objectSchema = ObjectSchema(RLMObjectBaseObjectSchema(obj)!)
    (objectSchema.rlmObjectSchema.properties + objectSchema.rlmObjectSchema.computedProperties)
      .map { (prop: $0, accessor: $0.swiftAccessor) }
      .forEach { $0.accessor?.observe($0.prop, on: obj) }
    return obj
  }
}

extension Projection: KeypathRecorder
{
  static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self
  {
    let obj = Self(projecting: PersistedType())
    obj.rootObject.lastAccessedNames = lastAccessedNames
    let objectSchema = ObjectSchema(RLMObjectBaseObjectSchema(obj.rootObject)!)
    (objectSchema.rlmObjectSchema.properties + objectSchema.rlmObjectSchema.computedProperties)
      .map { (prop: $0, accessor: $0.swiftAccessor) }
      .forEach { $0.accessor?.observe($0.prop, on: obj.rootObject) }
    return obj
  }
}

extension _DefaultConstructible
{
  static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> Self
  {
    let obj = Self()
    if var obj = obj as? PropertyNameConvertible
    {
      obj.lastAccessedNames = lastAccessedNames
    }
    return obj
  }
}

extension List: KeypathRecorder where Element: _Persistable {}
extension List: PropertyNameConvertible
{
  var propertyInformation: (key: String, isLegacy: Bool)?
  {
    (key: rlmArray.propertyKey, isLegacy: rlmArray.isLegacyProperty)
  }
}

extension Map: KeypathRecorder where Value: _Persistable {}
extension Map: PropertyNameConvertible
{
  var propertyInformation: (key: String, isLegacy: Bool)?
  {
    (key: rlmDictionary.propertyKey, isLegacy: rlmDictionary.isLegacyProperty)
  }
}

extension MutableSet: KeypathRecorder where Element: _Persistable {}
extension MutableSet: PropertyNameConvertible
{
  var propertyInformation: (key: String, isLegacy: Bool)?
  {
    (key: rlmSet.propertyKey, isLegacy: rlmSet.isLegacyProperty)
  }
}

extension LinkingObjects: KeypathRecorder where Element: _Persistable
{
  static func keyPathRecorder(with lastAccessedNames: NSMutableArray) -> LinkingObjects<Element>
  {
    var obj = Self(propertyName: "", handle: nil)
    obj.lastAccessedNames = lastAccessedNames
    return obj
  }
}

extension LinkingObjects: PropertyNameConvertible
{
  var propertyInformation: (key: String, isLegacy: Bool)?
  {
    guard let handle else { return nil }
    return (key: handle._propertyKey, isLegacy: handle._isLegacyProperty)
  }
}
