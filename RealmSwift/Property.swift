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

/**
 `Property` instances represent properties managed by a Realm in the context of an object schema. Such properties may be
 persisted to a Realm file or computed from other data in the Realm.

 When using Realm, property instances allow performing migrations and introspecting the database's schema.

 Property instances map to columns in the core database.
 */
@frozen public struct Property: CustomStringConvertible
{
  // MARK: Properties

  let rlmProperty: RLMProperty

  /// The name of the property.
  public var name: String { rlmProperty.name }

  /// The column name of the property in the database. This will be the same as the property name when no
  /// private name is provided on the property mapping.
  public var columnName: String { rlmProperty.columnName ?? name }

  /// The type of the property.
  public var type: PropertyType { rlmProperty.type }

  /// Indicates whether this property is an array of the property type.
  public var isArray: Bool { rlmProperty.array }

  /// Indicates whether this property is a set of the property type.
  public var isSet: Bool { rlmProperty.set }

  /// Indicates whether this property is a dictionary of the property type.
  public var isMap: Bool { rlmProperty.dictionary }

  /// Indicates whether this property is indexed.
  public var isIndexed: Bool { rlmProperty.indexed }

  /// Indicates whether this property is optional. (Note that certain numeric types must be wrapped in a
  /// `RealmOptional` instance in order to be declared as optional.)
  public var isOptional: Bool { rlmProperty.optional }

  /// For `Object` and `List` properties, the name of the class of object stored in the property.
  public var objectClassName: String? { rlmProperty.objectClassName }

  /// A human-readable description of the property object.
  public var description: String { rlmProperty.description }

  // MARK: Initializers

  init(_ rlmProperty: RLMProperty)
  {
    self.rlmProperty = rlmProperty
  }
}

// MARK: Equatable

extension Property: Equatable
{
  /// Returns whether the two properties are equal.
  public static func == (lhs: Property, rhs: Property) -> Bool
  {
    lhs.rlmProperty.isEqual(to: rhs.rlmProperty)
  }
}
