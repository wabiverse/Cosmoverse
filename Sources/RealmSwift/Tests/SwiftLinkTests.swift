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
import XCTest

class SwiftLinkTests: TestCase
{
  func testBasicLink()
  {
    let realm = realmWithTestPath()

    let owner = SwiftOwnerObject()
    owner.name = "Tim"
    owner.dog = SwiftDogObject()
    owner.dog!.dogName = "Harvie"

    try! realm.write { realm.add(owner) }

    let owners = realm.objects(SwiftOwnerObject.self)
    let dogs = realm.objects(SwiftDogObject.self)
    XCTAssertEqual(owners.count, Int(1), "Expecting 1 owner")
    XCTAssertEqual(dogs.count, Int(1), "Expecting 1 dog")
    XCTAssertEqual(owners[0].name, "Tim", "Tim is named Tim")
    XCTAssertEqual(dogs[0].dogName, "Harvie", "Harvie is named Harvie")

    XCTAssertEqual(owners[0].dog!.dogName, "Harvie", "Tim's dog should be Harvie")
  }

  func testMultipleOwnerLink()
  {
    let realm = realmWithTestPath()

    let owner = SwiftOwnerObject()
    owner.name = "Tim"
    owner.dog = SwiftDogObject()
    owner.dog!.dogName = "Harvie"

    try! realm.write { realm.add(owner) }

    XCTAssertEqual(realm.objects(SwiftOwnerObject.self).count, Int(1), "Expecting 1 owner")
    XCTAssertEqual(realm.objects(SwiftDogObject.self).count, Int(1), "Expecting 1 dog")

    realm.beginWrite()
    let fiel = realm.create(SwiftOwnerObject.self, value: ["Fiel", NSNull()])
    fiel.dog = owner.dog
    try! realm.commitWrite()

    XCTAssertEqual(realm.objects(SwiftOwnerObject.self).count, Int(2), "Expecting 2 owners")
    XCTAssertEqual(realm.objects(SwiftDogObject.self).count, Int(1), "Expecting 1 dog")
  }

  func testLinkRemoval()
  {
    let realm = realmWithTestPath()

    let owner = SwiftOwnerObject()
    owner.name = "Tim"
    owner.dog = SwiftDogObject()
    owner.dog!.dogName = "Harvie"

    try! realm.write { realm.add(owner) }

    XCTAssertEqual(realm.objects(SwiftOwnerObject.self).count, Int(1), "Expecting 1 owner")
    XCTAssertEqual(realm.objects(SwiftDogObject.self).count, Int(1), "Expecting 1 dog")

    try! realm.write { realm.delete(owner.dog!) }

    XCTAssertNil(owner.dog, "Dog should be nullified when deleted")

    // refresh owner and check
    let owner2 = realm.objects(SwiftOwnerObject.self).first!
    XCTAssertNotNil(owner2, "Should have 1 owner")
    XCTAssertNil(owner2.dog, "Dog should be nullified when deleted")
    XCTAssertEqual(realm.objects(SwiftDogObject.self).count, Int(0), "Expecting 0 dogs")
  }

  func testLinkingObjects()
  {
    let realm = realmWithTestPath()

    let owner = SwiftOwnerObject()
    owner.name = "Tim"
    owner.dog = SwiftDogObject()
    owner.dog!.dogName = "Harvie"

    XCTAssertEqual(0, owner.dog!.owners.count, "Linking objects are not available until the object is persisted")

    try! realm.write
    {
      realm.add(owner)
    }

    let owners = owner.dog!.owners
    XCTAssertEqual(1, owners.count)
    XCTAssertEqual(owner.name, owners.first!.name)

    try! realm.write
    {
      owner.dog = nil
    }

    XCTAssertEqual(0, owners.count)
  }

  func testLinkingObjectsWithNoPersistedProps()
  {
    let realm = realmWithTestPath()

    let target = OnlyComputedProps()

    let source1 = LinkToOnlyComputed()
    source1.value = 1
    source1.link = target

    XCTAssertEqual(target.backlinks.count, 0, "Linking objects are not available until the object is persisted")

    try! realm.write
    {
      realm.add(source1)
    }

    XCTAssertEqual(target.backlinks.count, 1)
    XCTAssertEqual(target.backlinks.first!.value, source1.value)

    let source2 = LinkToOnlyComputed()
    source2.value = 2
    source2.link = target

    XCTAssertEqual(target.backlinks.count, 1, "Linking objects to an unpersisted object are not available")
    try! realm.write
    {
      realm.add(source2)
    }

    XCTAssertEqual(target.backlinks.count, 2)
    XCTAssertTrue(target.backlinks.contains(where: { $0.value == 2 }))

    let targetWithNoLinks = OnlyComputedProps()
    try! realm.write
    {
      // Implicitly verify we can persist a RealmObject with no persisted properties and
      // no objects linking to it
      realm.add(targetWithNoLinks)
    }

    XCTAssertEqual(targetWithNoLinks.backlinks.count, 0, "No object is linking to targetWithNoLinks")
  }
}
