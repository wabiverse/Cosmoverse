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

/**
 This class represents Realm model object schemas.

 When using Realm, `ObjectSchema` instances allow performing migrations and introspecting the database's schema.

 Object schemas map to tables in the core database.
 */
@frozen public struct ObjectSchema: CustomStringConvertible
{
  // MARK: Properties

  let rlmObjectSchema: RLMObjectSchema

  /**
   An array of `Property` instances representing the managed properties of a class described by the schema.

   - see: `Property`
   */
  public var properties: [Property]
  {
    rlmObjectSchema.properties.map { Property($0) }
  }

  /// The name of the class the schema describes.
  public var className: String { rlmObjectSchema.className }

  /// The object class the schema describes.
  public var objectClass: AnyClass { rlmObjectSchema.objectClass }

  /// Whether this object is embedded.
  public var isEmbedded: Bool { rlmObjectSchema.isEmbedded }

  /// Whether this object is asymmetric.
  public var isAsymmetric: Bool { rlmObjectSchema.isAsymmetric }

  /// The property which serves as the primary key for the class the schema describes, if any.
  public var primaryKeyProperty: Property?
  {
    if let rlmProperty = rlmObjectSchema.primaryKeyProperty
    {
      return Property(rlmProperty)
    }
    return nil
  }

  /// A human-readable description of the properties contained in the object schema.
  public var description: String { rlmObjectSchema.description }

  // MARK: Initializers

  init(_ rlmObjectSchema: RLMObjectSchema)
  {
    self.rlmObjectSchema = rlmObjectSchema
  }

  // MARK: Property Retrieval

  /// Returns the property with the given name, if it exists.
  public subscript(propertyName: String) -> Property?
  {
    if let rlmProperty = rlmObjectSchema[propertyName]
    {
      return Property(rlmProperty)
    }
    return nil
  }
}

// MARK: Equatable

extension ObjectSchema: Equatable
{
  /// Returns whether the two object schemas are equal.
  public static func == (lhs: ObjectSchema, rhs: ObjectSchema) -> Bool
  {
    lhs.rlmObjectSchema.isEqual(to: rhs.rlmObjectSchema)
  }
}
