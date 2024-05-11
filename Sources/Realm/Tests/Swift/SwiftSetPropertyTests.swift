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

class SwiftRLMSetPropertyTests: RLMTestCase
{
  // Swift models

  func testBasicSet()
  {
    let string = SwiftRLMStringObject()
    string.stringCol = "string"

    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    realm.add(string)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(SwiftRLMStringObject.allObjects(in: realm).count, UInt(1), "There should be a single SwiftRLMStringObject in the realm")

    let set = SwiftRLMSetPropertyObject()
    set.name = "setObject"
    set.set.add(string)
    XCTAssertEqual(set.set.count, UInt(1))
    XCTAssertEqual(set.set.allObjects[0].stringCol, "string")

    realm.beginWriteTransaction()
    realm.add(set)
    set.set.add(string)
    try! realm.commitWriteTransaction()

    let setObjects = SwiftRLMSetPropertyObject.allObjects(in: realm) as! RLMResults<SwiftRLMSetPropertyObject>

    XCTAssertEqual(setObjects.count, UInt(1), "There should be a single SwiftRLMStringObject in the realm")
    let cmp = setObjects[0].set.allObjects[0]
    XCTAssertTrue(string.isEqual(to: cmp), "First array object should be the string object we added")
  }

  func testPopulateEmptySet()
  {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()
    let set = SwiftRLMSetPropertyObject.create(in: realm, withValue: ["setObject"])
    XCTAssertNotNil(set.set, "Should be able to get an empty set")
    XCTAssertEqual(set.set.count, UInt(0), "Should start with no set elements")

    let obj = SwiftRLMStringObject()
    obj.stringCol = "a"
    set.set.add(obj)
    set.set.add(SwiftRLMStringObject.create(in: realm, withValue: ["b"]))
    set.set.add(obj)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(set.set.count, UInt(2), "Should have two elements in array")
    var count = 0
    set.set.forEach
    {
      guard let o = $0 as? SwiftRLMStringObject
      else
      {
        return XCTFail("expected SwiftRLMStringObject")
      }
      XCTAssertTrue(o.stringCol.contains("a") || o.stringCol.contains("b"))
      count += 1
    }
    XCTAssertEqual(count, 2, "Loop should run 3 times")

    for obj in set.set
    {
      XCTAssertFalse(obj.description.isEmpty, "Object should have description")
    }
  }

  func testModifyDetatchedSet()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    let setObj = SwiftRLMSetPropertyObject.create(in: realm, withValue: ["setObject"])
    XCTAssertNotNil(setObj.set, "Should be able to get an empty set")
    XCTAssertEqual(setObj.set.count, UInt(0), "Should start with no set elements")

    let obj = SwiftRLMStringObject()
    obj.stringCol = "a"
    let set = setObj.set
    set.add(obj)
    set.add(SwiftRLMStringObject.create(in: realm, withValue: ["b"]))
    try! realm.commitWriteTransaction()

    XCTAssertEqual(set.count, UInt(2), "Should have two elements in set")
    var count = 0
    set.forEach
    {
      guard let o = $0 as? SwiftRLMStringObject
      else
      {
        return XCTFail("expected SwiftRLMStringObject")
      }
      XCTAssertTrue(o.stringCol.contains("a") || o.stringCol.contains("b"))
      count += 1
    }
    XCTAssertEqual(count, 2, "Loop should run twice")
  }

  func testInsertMultiple()
  {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()

    let obj = SwiftRLMSetPropertyObject.create(in: realm, withValue: ["setObject"])
    let child1 = SwiftRLMStringObject.create(in: realm, withValue: ["a"])
    let child2 = SwiftRLMStringObject()
    child2.stringCol = "b"
    obj.set.addObjects([child2, child1] as NSArray)
    try! realm.commitWriteTransaction()

    let children = SwiftRLMStringObject.allObjects(in: realm)
    XCTAssertEqual((children[0] as! SwiftRLMStringObject).stringCol, "a", "First child should be 'a'")
    XCTAssertEqual((children[1] as! SwiftRLMStringObject).stringCol, "b", "Second child should be 'b'")
  }

  func testUnmanaged()
  {
    let realm = realmWithTestPath()

    let set = SwiftRLMSetPropertyObject()
    set.name = "name"
    XCTAssertNotNil(set.set, "RLMSet property should get created on access")

    let obj = SwiftRLMStringObject()
    obj.stringCol = "a"
    set.set.add(obj)
    set.set.add(obj)

    realm.beginWriteTransaction()
    realm.add(set)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(set.set.count, UInt(1), "Should have one element in set")
    var count = 0
    set.set.forEach
    {
      guard let o = $0 as? SwiftRLMStringObject
      else
      {
        return XCTFail("expected SwiftRLMStringObject")
      }
      XCTAssertTrue(o.stringCol.contains("a") || o.stringCol.contains("b"))
      count += 1
    }
    XCTAssertEqual(count, 1, "Loop should run once")
  }

  // Objective-C models

  func testBasicSet_objc()
  {
    let string = StringObject()
    string.stringCol = "string"

    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    realm.add(string)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(StringObject.allObjects(in: realm).count, UInt(1), "There should be a single StringObject in the realm")

    let set = SetPropertyObject()
    set.name = "arrayObject"
    set.set.add(string)

    realm.beginWriteTransaction()
    realm.add(set)
    try! realm.commitWriteTransaction()

    let setObjects = SetPropertyObject.allObjects(in: realm)

    XCTAssertEqual(setObjects.count, UInt(1), "There should be a single StringObject in the realm")
    let cmp = (setObjects.firstObject() as! SetPropertyObject).set.allObjects[0]
    XCTAssertTrue(string.isEqual(to: cmp), "First set object should be the string object we added")
  }

  func testPopulateEmptySet_objc()
  {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()
    let set = SetPropertyObject.create(in: realm, withValue: ["setObject"])
    XCTAssertNotNil(set.set, "Should be able to get an empty set")
    XCTAssertEqual(set.set.count, UInt(0), "Should start with no set elements")

    let obj = StringObject()
    obj.stringCol = "a"
    set.set.add(obj)
    set.set.add(StringObject.create(in: realm, withValue: ["b"]))
    set.set.add(obj)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(set.set.count, UInt(2), "Should have two elements in set")
    var count = 0
    (set.set as RLMSet<StringObject>).forEach
    {
      guard let o = $0 as? StringObject
      else
      {
        return XCTFail("expected StringObject")
      }
      XCTAssertTrue(o.stringCol.contains("a") || o.stringCol.contains("b"))
      count += 1
    }
    XCTAssertEqual(count, 2, "Loop should run 2 times")
    set.set.allObjects.forEach
    { o in
      XCTAssertFalse(o.description.isEmpty, "Object should have description")
    }
  }

  func testModifyDetatchedSet_objc()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    let setObj = SetPropertyObject.create(in: realm, withValue: ["setObject"])
    XCTAssertNotNil(setObj.set, "Should be able to get an empty set")
    XCTAssertEqual(setObj.set.count, UInt(0), "Should start with no set elements")

    let obj = StringObject()
    obj.stringCol = "a"
    let set = setObj.set!
    set.add(obj)
    set.add(StringObject.create(in: realm, withValue: ["b"]))
    try! realm.commitWriteTransaction()

    XCTAssertEqual(set.count, UInt(2), "Should have two elements in set")
    var count = 0
    (set as RLMSet<StringObject>).forEach
    {
      guard let o = $0 as? StringObject
      else
      {
        return XCTFail("expected StringObject")
      }
      XCTAssertTrue(o.stringCol.contains("a") || o.stringCol.contains("b"))
      count += 1
    }
    XCTAssertEqual(count, 2, "Loop should run twice")
  }

  func testInsertMultiple_objc()
  {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()

    let obj = SetPropertyObject.create(in: realm, withValue: ["setObject"])
    let child1 = StringObject.create(in: realm, withValue: ["a"])
    let child2 = StringObject()
    child2.stringCol = "b"
    obj.set.addObjects([child2, child1] as NSArray)
    try! realm.commitWriteTransaction()

    let children = StringObject.allObjects(in: realm)
    XCTAssertEqual((children[0] as! StringObject).stringCol!, "a", "First child should be 'a'")
    XCTAssertEqual((children[1] as! StringObject).stringCol!, "b", "Second child should be 'b'")
  }

  func testUnmanaged_objc()
  {
    let realm = realmWithTestPath()

    let set = SetPropertyObject()
    set.name = "name"
    XCTAssertNotNil(set.set, "RLMSet property should get created on access")

    let obj = StringObject()
    obj.stringCol = "a"
    set.set.add(obj)
    set.set.add(obj)

    realm.beginWriteTransaction()
    realm.add(set)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(set.set.count, UInt(1), "Should have one element in set")
    var count = 0
    (set.set as RLMSet<StringObject>).forEach
    {
      guard let o = $0 as? StringObject
      else
      {
        return XCTFail("expected SwiftRLMStringObject")
      }
      XCTAssertTrue(o.stringCol.contains("a"))
      count += 1
    }
    XCTAssertEqual(count, 1, "Loop should run once")
  }
}
