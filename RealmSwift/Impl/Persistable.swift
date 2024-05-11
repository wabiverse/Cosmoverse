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

/// An opaque identifier for each property on a class. Happens to currently be
/// the property's index in the object schema, but that's not something that any
/// of the Swift code should rely on. In the future it may make sense to change
/// this to the ColKey.
public typealias PropertyKey = UInt16

/// A tag protocol used in schema discovery to find @Persisted properties
protocol DiscoverablePersistedProperty: _RealmSchemaDiscoverable {}

public protocol _HasPersistedType: _ObjcBridgeable
{
  /// The type which is actually stored in the Realm. This is Self for types
  /// we support directly, but may be a different type for enums and mapped types.
  associatedtype PersistedType: _ObjcBridgeable
}

/// These two types need PersistedType for collection aggregate functions but
/// aren't persistable or valid collection types
extension NSNumber: _HasPersistedType
{
  public typealias PersistedType = NSNumber
}

extension NSDate: _HasPersistedType
{
  public typealias PersistedType = NSDate
}

/// A type which can be stored by the @Persisted property wrapper
public protocol _Persistable: _RealmSchemaDiscoverable, _HasPersistedType where PersistedType: _Persistable, PersistedType.PersistedType.PersistedType == PersistedType.PersistedType
{
  /// Read a value of this type from the target object
  static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Self
  /// Set a value of this type on the target object
  static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Self)
  /// Set the swiftAccessor for this type if the default PersistedPropertyAccessor
  /// is not suitable.
  static func _rlmSetAccessor(_ prop: RLMProperty)
  /// Do the values of this type need to be cached on the Persisted?
  static var _rlmRequiresCaching: Bool { get }
  /// Get the zero/empty/nil value for this type. Used to supply a default
  /// when the user does not declare one in their model.
  static func _rlmDefaultValue() -> Self
}

public extension _Persistable
{
  static var _rlmRequiresCaching: Bool
  {
    false
  }
}

/// A type which can appear inside Optional<T> in a @Persisted property
public protocol _PersistableInsideOptional: _Persistable where PersistedType: _PersistableInsideOptional
{
  /// Read an optional value of this type from the target object
  static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self?
}

public extension _PersistableInsideOptional
{
  static func _rlmSetAccessor(_ prop: RLMProperty)
  {
    if prop.optional
    {
      prop.swiftAccessor = PersistedPropertyAccessor<Self?>.self
    }
    else
    {
      prop.swiftAccessor = PersistedPropertyAccessor<Self>.self
    }
  }
}

/// Default definition of _rlmDefaultValue used by everything exception for
/// Optional, which requires doing Optional<T>.none rather than Optional<T>().
public protocol _DefaultConstructible
{
  init()
}

public extension _Persistable where Self: _DefaultConstructible
{
  static func _rlmDefaultValue() -> Self
  {
    .init()
  }
}
