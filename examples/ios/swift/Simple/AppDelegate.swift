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

import RealmSwift
import UIKit

class Dog: Object
{
  @Persisted var name: String
  @Persisted var age: Int
}

class Person: Object
{
  @Persisted var name: String
  @Persisted var dogs: List<Dog>
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
  var window: UIWindow?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
  {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = UIViewController()
    window?.makeKeyAndVisible()

    _ = try! Realm.deleteFiles(for: Realm.Configuration.defaultConfiguration)

    // Create a standalone object
    let mydog = Dog()

    // Set & read properties
    mydog.name = "Rex"
    mydog.age = 9
    print("Name of dog: \(mydog.name)")

    // Realms are used to group data together
    let realm = try! Realm() // Create realm pointing to default file

    // Save your object
    realm.beginWrite()
    realm.add(mydog)
    try! realm.commitWrite()

    // Query
    let results = realm.objects(Dog.self).filter("name contains 'x'")

    // Queries are chainable!
    let results2 = results.filter("age > 8")
    print("Number of dogs: \(results.count)")
    print("Dogs older than eight: \(results2.count)")

    // Link objects
    let person = Person()
    person.name = "Tim"
    person.dogs.append(mydog)

    try! realm.write
    {
      realm.add(person)
    }

    // Multi-threading
    DispatchQueue.global().async
    {
      autoreleasepool
      {
        let otherRealm = try! Realm()
        let otherResults = otherRealm.objects(Dog.self).filter("name contains 'Rex'")
        print("Number of dogs \(otherResults.count)")
      }
    }

    return true
  }
}
