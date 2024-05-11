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
 `Schema` instances represent collections of model object schemas managed by a Realm.

 When using Realm, `Schema` instances allow performing migrations and introspecting the database's schema.

 Schemas map to collections of tables in the core database.
 */
@frozen public struct Schema: CustomStringConvertible
{
  // MARK: Properties

  let rlmSchema: RLMSchema

  /**
   An array of `ObjectSchema`s for all object types in the Realm.

   This property is intended to be used during migrations for dynamic introspection.
   */
  public var objectSchema: [ObjectSchema]
  {
    rlmSchema.objectSchema.map(ObjectSchema.init)
  }

  /// A human-readable description of the object schemas contained within.
  public var description: String { rlmSchema.description }

  // MARK: Initializers

  init(_ rlmSchema: RLMSchema)
  {
    self.rlmSchema = rlmSchema
  }

  // MARK: ObjectSchema Retrieval

  /// Looks up and returns an `ObjectSchema` for the given class name in the Realm, if it exists.
  public subscript(className: String) -> ObjectSchema?
  {
    if let rlmObjectSchema = rlmSchema.schema(forClassName: className)
    {
      return ObjectSchema(rlmObjectSchema)
    }
    return nil
  }
}

// MARK: Equatable

extension Schema: Equatable
{
  /// Returns whether the two schemas are equal.
  public static func == (lhs: Schema, rhs: Schema) -> Bool
  {
    lhs.rlmSchema.isEqual(to: rhs.rlmSchema)
  }
}
