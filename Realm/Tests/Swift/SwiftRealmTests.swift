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
import XCTest

#if canImport(RealmTestSupport)
  import RealmTestSupport
#endif

@available(iOS 13.0, visionOS 1.0, *) // For @MainActor
@MainActor
class SwiftRLMRealmTests: RLMTestCase
{
  // No models

  func testRealmExists()
  {
    let realm = realmWithTestPath()
    XCTAssertNotNil(realm, "realm should not be nil")
    XCTAssertTrue((realm as AnyObject) is RLMRealm, "realm should be of class RLMRealm")
  }

  func testEmptyWriteTransaction()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    try! realm.commitWriteTransaction()
  }

  // Swift models

  func testRealmAddAndRemoveObjects()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = SwiftRLMStringObject.create(in: realm, withValue: ["a"])
    _ = SwiftRLMStringObject.create(in: realm, withValue: ["b"])
    _ = SwiftRLMStringObject.create(in: realm, withValue: ["c"])
    XCTAssertEqual(SwiftRLMStringObject.allObjects(in: realm).count, UInt(3), "Expecting 3 objects")
    try! realm.commitWriteTransaction()

    // test again after write transaction
    var objects = SwiftRLMStringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(3), "Expecting 3 objects")
    XCTAssertEqual((objects[0] as! SwiftRLMStringObject).stringCol, "a", "Expecting column to be 'a'")

    realm.beginWriteTransaction()
    realm.delete(objects[2] as! SwiftRLMStringObject)
    realm.delete(objects[0] as! SwiftRLMStringObject)
    XCTAssertEqual(SwiftRLMStringObject.allObjects(in: realm).count, UInt(1), "Expecting 1 object")
    try! realm.commitWriteTransaction()

    objects = SwiftRLMStringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1), "Expecting 1 object")
    XCTAssertEqual((objects[0] as! SwiftRLMStringObject).stringCol, "b", "Expecting column to be 'b'")
  }

  func testRealmIsUpdatedAfterBackgroundUpdate()
  {
    let realm = realmWithTestPath()

    // we have two notifications, one for opening the realm, and a second when performing our transaction
    let notificationFired = expectation(description: "notification fired")
    let token = realm.addNotificationBlock
    { _, realm in
      XCTAssertNotNil(realm, "Realm should not be nil")
      notificationFired.fulfill()
    }

    dispatchAsync
    {
      let realm = self.realmWithTestPath()
      realm.beginWriteTransaction()
      _ = SwiftRLMStringObject.create(in: realm, withValue: ["string"])
      try! realm.commitWriteTransaction()
    }
    waitForExpectations(timeout: 2.0, handler: nil)
    token.invalidate()

    // get object
    let objects = SwiftRLMStringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
    XCTAssertEqual((objects[0] as! SwiftRLMStringObject).stringCol, "string", "Value of first column should be 'string'")
  }

  func testRealmIgnoresProperties()
  {
    let realm = realmWithTestPath()

    let object = SwiftRLMIgnoredPropertiesObject()
    realm.beginWriteTransaction()
    object.name = "@fz"
    object.age = 31
    realm.add(object)
    try! realm.commitWriteTransaction()

    // This shouldn't do anything.
    realm.beginWriteTransaction()
    object.runtimeProperty = NSObject()
    try! realm.commitWriteTransaction()

    let objects = SwiftRLMIgnoredPropertiesObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type SwiftRLMIgnoredPropertiesObject")
    let retrievedObject = objects[0] as! SwiftRLMIgnoredPropertiesObject
    XCTAssertNil(retrievedObject.runtimeProperty, "Ignored property should be nil")
    XCTAssertEqual(retrievedObject.name, "@fz", "Value of the name column doesn't match the assigned one.")
    XCTAssertEqual(retrievedObject.objectSchema.properties.count, 2, "Only 'name' and 'age' properties should be detected by Realm")
  }

  func testUpdatingSortedArrayAfterBackgroundUpdate()
  {
    let realm = realmWithTestPath()
    let objs = SwiftRLMIntObject.allObjects(in: realm)
    let objects = SwiftRLMIntObject.allObjects(in: realm).sortedResults(usingKeyPath: "intCol", ascending: true)
    let updateComplete = expectation(description: "background update complete")

    let token = realm.addNotificationBlock
    { _, _ in
      XCTAssertEqual(objs.count, UInt(2))
      XCTAssertEqual(objs.sortedResults(usingKeyPath: "intCol", ascending: true).count, UInt(2))
      XCTAssertEqual(objects.count, UInt(2))
      updateComplete.fulfill()
    }

    dispatchAsync
    {
      let realm = self.realmWithTestPath()
      try! realm.transaction
      {
        var obj = SwiftRLMIntObject()
        obj.intCol = 2
        realm.add(obj)

        obj = SwiftRLMIntObject()
        obj.intCol = 1
        realm.add(obj)
      }
    }

    waitForExpectations(timeout: 2.0, handler: nil)
    token.invalidate()
  }

  func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate()
  {
    let realm = realmWithTestPath()

    let notificationFired = expectation(description: "notification fired")
    let token = realm.addNotificationBlock
    { _, realm in
      XCTAssertNotNil(realm, "Realm should not be nil")
      notificationFired.fulfill()
    }

    dispatchAsync
    {
      let realm = self.realmWithTestPath()
      let obj = SwiftRLMStringObject(value: ["string"])
      realm.beginWriteTransaction()
      realm.add(obj)
      try! realm.commitWriteTransaction()

      let objects = SwiftRLMStringObject.allObjects(in: realm)
      XCTAssertEqual(objects.count, UInt(1))
      XCTAssertEqual((objects[0] as! SwiftRLMStringObject).stringCol, "string")
    }

    waitForExpectations(timeout: 2.0, handler: nil)
    token.invalidate()

    // get object
    let objects = SwiftRLMStringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1))
    XCTAssertEqual((objects[0] as! SwiftRLMStringObject).stringCol, "string")
  }

  // Objective-C models

  func testRealmAddAndRemoveObjects_objc()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = StringObject.create(in: realm, withValue: ["a"])
    _ = StringObject.create(in: realm, withValue: ["b"])
    _ = StringObject.create(in: realm, withValue: ["c"])
    XCTAssertEqual(StringObject.allObjects(in: realm).count, UInt(3), "Expecting 3 objects")
    try! realm.commitWriteTransaction()

    // test again after write transaction
    var objects = StringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(3), "Expecting 3 objects")
    XCTAssertEqual((objects[0] as! StringObject).stringCol!, "a", "Expecting column to be 'a'")

    realm.beginWriteTransaction()
    realm.delete(objects[2] as! StringObject)
    realm.delete(objects[0] as! StringObject)
    XCTAssertEqual(StringObject.allObjects(in: realm).count, UInt(1), "Expecting 1 object")
    try! realm.commitWriteTransaction()

    objects = StringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1), "Expecting 1 object")
    XCTAssertEqual((objects[0] as! StringObject).stringCol!, "b", "Expecting column to be 'b'")
  }

  func testRealmIsUpdatedAfterBackgroundUpdate_objc()
  {
    let realm = realmWithTestPath()

    // we have two notifications, one for opening the realm, and a second when performing our transaction
    let notificationFired = expectation(description: "notification fired")
    let token = realm.addNotificationBlock
    { note, realm in
      XCTAssertNotNil(realm, "Realm should not be nil")
      if note == RLMNotification.DidChange
      {
        notificationFired.fulfill()
      }
    }

    dispatchAsync
    {
      let realm = self.realmWithTestPath()
      realm.beginWriteTransaction()
      _ = StringObject.create(in: realm, withValue: ["string"])
      try! realm.commitWriteTransaction()
    }
    waitForExpectations(timeout: 2.0, handler: nil)
    token.invalidate()

    // get object
    let objects = StringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
    XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
  }

  func testRealmIsUpdatedImmediatelyAfterBackgroundUpdate_objc()
  {
    let realm = realmWithTestPath()

    // we have two notifications, one for opening the realm, and a second when performing our transaction
    let notificationFired = expectation(description: "notification fired")
    let token = realm.addNotificationBlock
    { _, realm in
      XCTAssertNotNil(realm, "Realm should not be nil")
      notificationFired.fulfill()
    }

    dispatchAsync
    {
      let realm = self.realmWithTestPath()
      let obj = StringObject(value: ["string"])
      try! realm.transaction
      {
        realm.add(obj)
      }

      let objects = StringObject.allObjects(in: realm)
      XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type StringObject")
      XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
    }

    waitForExpectations(timeout: 2.0, handler: nil)
    token.invalidate()

    // get object
    let objects = StringObject.allObjects(in: realm)
    XCTAssertEqual(objects.count, UInt(1), "There should be 1 object of type RLMTestObject")
    XCTAssertEqual((objects[0] as! StringObject).stringCol!, "string", "Value of first column should be 'string'")
  }
}
