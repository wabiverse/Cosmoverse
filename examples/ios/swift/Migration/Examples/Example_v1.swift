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

#if SCHEMA_VERSION_1

  import Foundation
  import RealmSwift

  // MARK: - Schema

  let schemaVersion = 1

  // Changes from previous version:
  // - combine `firstName` and `lastName` into `fullName`

  class Person: Object
  {
    @Persisted var fullName = ""
    @Persisted var age = 0
    convenience init(fullName: String, age: Int)
    {
      self.init()
      self.fullName = fullName
      self.age = age
    }
  }

  // MARK: - Migration

  /// Migration block to migrate from *any* previous version to this version.
  let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
    if oldSchemaVersion < 1
    {
      migration.enumerateObjects(ofType: Person.className())
      { oldObject, newObject in
        // combine name fields into a single field
        let firstName = oldObject!["firstName"] as! String
        let lastName = oldObject!["lastName"] as! String
        newObject!["fullName"] = "\(firstName) \(lastName)"
      }
    }
  }

  /// This block checks if the migration led to the expected result.
  /// All older versions should have been migrated to the below stated `exampleData`.
  let migrationCheck: (Realm) -> Void = { realm in
    let persons = realm.objects(Person.self)
    assert(persons.count == 3)
    assert(persons[0].fullName == "John Doe")
    assert(persons[0].age == 42)
    assert(persons[1].fullName == "Jane Doe")
    assert(persons[1].age == 43)
    assert(persons[2].fullName == "John Smith")
    assert(persons[2].age == 44)
  }

  // MARK: - Example data

  /// Example data for this schema version.
  let exampleData: (Realm) -> Void = { realm in
    let person1 = Person(fullName: "John Doe", age: 42)
    let person2 = Person(fullName: "Jane Doe", age: 43)
    let person3 = Person(fullName: "John Smith", age: 44)
    realm.add([person1, person2, person3])
  }

#endif
