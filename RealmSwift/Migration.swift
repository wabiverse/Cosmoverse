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
 The type of a migration block used to migrate a Realm.

 - parameter migration:  A `Migration` object used to perform the migration. The migration object allows you to
                         enumerate and alter any existing objects which require migration.

 - parameter oldSchemaVersion: The schema version of the Realm being migrated.
 */
public typealias MigrationBlock = @Sendable (_ migration: Migration, _ oldSchemaVersion: UInt64) -> Void

/// An object class used during migrations.
public typealias MigrationObject = DynamicObject

/**
 A block type which provides both the old and new versions of an object in the Realm. Object
 properties can only be accessed using subscripting.

 - parameter oldObject: The object from the original Realm (read-only).
 - parameter newObject: The object from the migrated Realm (read-write).
 */
public typealias MigrationObjectEnumerateBlock = (_ oldObject: MigrationObject?, _ newObject: MigrationObject?) -> Void

/**
 Returns the schema version for a Realm at a given local URL.

 - parameter fileURL:       Local URL to a Realm file.
 - parameter encryptionKey: 64-byte key used to encrypt the file, or `nil` if it is unencrypted.

 - throws: An `NSError` that describes the problem.
 */
public func schemaVersionAtURL(_ fileURL: URL, encryptionKey: Data? = nil) throws -> UInt64
{
  var error: NSError?
  let version = RLMRealm.__schemaVersion(at: fileURL, encryptionKey: encryptionKey, error: &error)
  guard version != RLMNotVersioned
  else
  {
    throw error!
  }
  return version
}

public extension Realm
{
  /**
   Performs the given Realm configuration's migration block on a Realm at the given path.

   This method is called automatically when opening a Realm for the first time and does not need to be called
   explicitly. You can choose to call this method to control exactly when and how migrations are performed.

   - parameter configuration: The Realm configuration used to open and migrate the Realm.
   */
  static func performMigration(for configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) throws
  {
    try RLMRealm.performMigration(for: configuration.rlmConfiguration)
  }
}

/**
 `Migration` instances encapsulate information intended to facilitate a schema migration.

 A `Migration` instance is passed into a user-defined `MigrationBlock` block when updating the version of a Realm. This
 instance provides access to the old and new database schemas, the objects in the Realm, and provides functionality for
 modifying the Realm during the migration.
 */
public typealias Migration = RLMMigration
public extension Migration
{
  // MARK: Properties

  /// The old schema, describing the Realm before applying a migration.
  var oldSchema: Schema { Schema(__oldSchema) }

  /// The new schema, describing the Realm after applying a migration.
  var newSchema: Schema { Schema(__newSchema) }

  // MARK: Altering Objects During a Migration

  /**
   Enumerates all the objects of a given type in this Realm, providing both the old and new versions of each object.
   Properties on an object can be accessed using subscripting.

   - parameter objectClassName: The name of the `Object` class to enumerate.
   - parameter block:           The block providing both the old and new versions of an object in this Realm.
   */
  func enumerateObjects(ofType typeName: String, _ block: MigrationObjectEnumerateBlock)
  {
    __enumerateObjects(typeName)
    { oldObject, newObject in
      block(unsafeBitCast(oldObject, to: MigrationObject.self),
            unsafeBitCast(newObject, to: MigrationObject.self))
    }
  }

  /**
   Creates and returns an `Object` of type `className` in the Realm being migrated.

   The `value` argument is used to populate the object. It can be a key-value coding compliant object, an array or
   dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing one element for each
   managed property. An exception will be thrown if any required properties are not present and those properties were
   not defined with default values.

   When passing in an `Array` as the `value` argument, all properties must be present, valid and in the same order as
   the properties defined in the model.

   - parameter className: The name of the `Object` class to create.
   - parameter value:     The value used to populate the created object.

   - returns: The newly created object.
   */
  @discardableResult
  func create(_ typeName: String, value: Any = [Any]()) -> MigrationObject
  {
    unsafeBitCast(__createObject(typeName, withValue: value), to: MigrationObject.self)
  }

  /**
   Deletes an object from a Realm during a migration.

   It is permitted to call this method from within the block passed to `enumerate(_:block:)`.

   - parameter object: An object to be deleted from the Realm being migrated.
   */
  func delete(_ object: MigrationObject)
  {
    __delete(object.unsafeCastToRLMObject())
  }

  /**
   Deletes the data for the class with the given name.

   All objects of the given class will be deleted. If the `Object` subclass no longer exists in your program, any
   remaining metadata for the class will be removed from the Realm file.

   - parameter objectClassName: The name of the `Object` class to delete.

   - returns: A Boolean value indicating whether there was any data to delete.
   */
  @discardableResult
  func deleteData(forType typeName: String) -> Bool
  {
    __deleteData(forClassName: typeName)
  }

  /**
   Renames a property of the given class from `oldName` to `newName`.

   - parameter className:  The name of the class whose property should be renamed. This class must be present
                           in both the old and new Realm schemas.
   - parameter oldName:    The old column name for the property to be renamed. There must not be a property with this name in
                           the class as defined by the new Realm schema.
   - parameter newName:    The new column name for the property to be renamed. There must not be a property with this name in
                           the class as defined by the old Realm schema.
   */
  func renameProperty(onType typeName: String, from oldName: String, to newName: String)
  {
    __renameProperty(forClass: typeName, oldName: oldName, newName: newName)
  }
}
