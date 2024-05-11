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
import RealmSwift

//: I. Define the data entities

class Person: Object
{
  @Persisted var name: String
  @Persisted var age: Int
  @Persisted var spouse: Person?
  @Persisted var cars: List<Car>

  override var description: String { "Person {\(name), \(age), \(spouse?.name ?? "nil")}" }
}

class Car: Object
{
  @Persisted var brand: String
  @Persisted var name: String?
  @Persisted var year: Int

  override var description: String { "Car {\(brand), \(name), \(year)}" }
}

//: II. Init the realm file

let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TemporaryRealm"))

//: III. Create the objects

let car1 = Car(value: ["brand": "BMW", "year": 1980])

let car2 = Car()
car2.brand = "DeLorean"
car2.name = "Outatime"
car2.year = 1981

/// people
let wife = Person()
wife.name = "Jennifer"
wife.cars.append(objectsIn: [car1, car2])
wife.age = 47

let husband = Person(value: [
  "name": "Marty",
  "age": 47,
  "spouse": wife
])

wife.spouse = husband

//: IV. Write objects to the realm

try! realm.write
{
  realm.add(husband)
}

//: V. Read objects back from the realm

let favorites = ["Jennifer"]

let favoritePeopleWithSpousesAndCars = realm.objects(Person.self)
  .filter("cars.@count > 1 && spouse != nil && name IN %@", favorites)
  .sorted(byKeyPath: "age")

for person in favoritePeopleWithSpousesAndCars
{
  person.name
  person.age

  guard let car = person.cars.first
  else
  {
    continue
  }
  car.name
  car.brand

  //: VI. Update objects

  try! realm.write
  {
    car.year += 1
  }
  car.year
}

//: VII. Delete objects

try! realm.write
{
  realm.deleteAll()
}

realm.objects(Person.self).count
//: Thanks! To learn more about Realm go to https://www.mongodb.com/docs/realm/
