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
import Realm.Dynamic
import Realm.Private
import XCTest

#if canImport(RealmTestSupport)
  import RealmTestSupport
#endif

class SwiftRLMDynamicTests: RLMTestCase
{
  // Swift models

  func testDynamicRealmExists()
  {
    autoreleasepool
    {
      // open realm in autoreleasepool to create tables and then dispose
      let realm = RLMRealm(url: RLMTestRealmURL())
      realm.beginWriteTransaction()
      _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column1", 1])
      _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column2", 2])
      try! realm.commitWriteTransaction()
    }
    let dyrealm = realm(withTestPathAndSchema: nil)
    XCTAssertNotNil(dyrealm, "realm should not be nil")

    // verify schema
    let dynSchema = dyrealm.schema[SwiftRLMDynamicObject.className()]
    XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
    XCTAssertEqual(dynSchema.properties.count, Int(2))
    XCTAssertEqual(dynSchema.properties[0].name, "stringCol")
    XCTAssertEqual(dynSchema.properties[1].type, RLMPropertyType.int)

    // verify object type
    let array = SwiftRLMDynamicObject.allObjects(in: dyrealm)
    XCTAssertEqual(array.count, UInt(2))
    XCTAssertEqual(array.objectClassName, SwiftRLMDynamicObject.className())
  }

  func testDynamicProperties()
  {
    autoreleasepool
    {
      // open realm in autoreleasepool to create tables and then dispose
      let realm = RLMRealm(url: RLMTestRealmURL())
      realm.beginWriteTransaction()
      _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column1", 1])
      _ = SwiftRLMDynamicObject.create(in: realm, withValue: ["column2", 2])
      try! realm.commitWriteTransaction()
    }

    // verify properties
    let dyrealm = realm(withTestPathAndSchema: nil)
    let array = dyrealm.allObjects("SwiftRLMDynamicObject")

    XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
    XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
  }

  // Objective-C models

  func testDynamicRealmExists_objc()
  {
    autoreleasepool
    {
      // open realm in autoreleasepool to create tables and then dispose
      let realm = RLMRealm(url: RLMTestRealmURL())
      realm.beginWriteTransaction()
      _ = DynamicTestObject.create(in: realm, withValue: ["column1", 1])
      _ = DynamicTestObject.create(in: realm, withValue: ["column2", 2])
      try! realm.commitWriteTransaction()
    }
    let dyrealm = realm(withTestPathAndSchema: nil)
    XCTAssertNotNil(dyrealm, "realm should not be nil")

    // verify schema
    let dynSchema = dyrealm.schema[DynamicTestObject.className()]
    XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
    XCTAssertTrue(dynSchema.properties.count == 2)
    XCTAssertTrue(dynSchema.properties[0].name == "stringCol")
    XCTAssertTrue(dynSchema.properties[1].type == RLMPropertyType.int)

    // verify object type
    let array = DynamicTestObject.allObjects(in: dyrealm)
    XCTAssertEqual(array.count, UInt(2))
    XCTAssertEqual(array.objectClassName, DynamicTestObject.className())
  }

  func testDynamicProperties_objc()
  {
    autoreleasepool
    {
      // open realm in autoreleasepool to create tables and then dispose
      let realm = RLMRealm(url: RLMTestRealmURL())
      realm.beginWriteTransaction()
      _ = DynamicTestObject.create(in: realm, withValue: ["column1", 1])
      _ = DynamicTestObject.create(in: realm, withValue: ["column2", 2])
      try! realm.commitWriteTransaction()
    }

    // verify properties
    let dyrealm = realm(withTestPathAndSchema: nil)
    let array = dyrealm.allObjects("DynamicTestObject")

    XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
    XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
  }

  func testDynamicTypes_objc()
  {
    let obj1 = AllTypesObject.values(1, stringObject: nil, mixedObject: nil)!
    let obj2 = AllTypesObject.values(2,
                                     stringObject: StringObject(value: ["string"]),
                                     mixedObject: MixedObject(value: ["string"]))!

    autoreleasepool
    {
      // open realm in autoreleasepool to create tables and then dispose
      let realm = self.realmWithTestPath()
      realm.beginWriteTransaction()
      _ = AllTypesObject.create(in: realm, withValue: obj1)
      _ = AllTypesObject.create(in: realm, withValue: obj2)
      try! realm.commitWriteTransaction()
    }

    // verify properties
    let dyrealm = realm(withTestPathAndSchema: nil)
    let results = dyrealm.allObjects(AllTypesObject.className())
    XCTAssertEqual(results.count, UInt(2))
    let robj1 = results[0]
    let robj2 = results[1]

    let schema = dyrealm.schema[AllTypesObject.className()]
    let props = schema.properties.filter { $0.type != .object }
    for prop in props
    {
      XCTAssertTrue((obj1[prop.name] as AnyObject).isEqual(robj1[prop.name]))
      XCTAssertTrue((obj2[prop.name] as AnyObject).isEqual(robj2[prop.name]))
    }

    // check sub object type
    XCTAssertTrue(schema.properties[12].objectClassName! == "StringObject")
    XCTAssertTrue(schema.properties[13].objectClassName! == "MixedObject")

    // check object equality
    XCTAssertNil(robj1["objectCol"], "object should be nil")
    XCTAssertNil(robj1["mixedObjectCol"], "object should be nil")
    XCTAssertTrue((robj2["objectCol"] as! RLMObject)["stringCol"] as! String == "string")
    XCTAssertTrue((robj2["mixedObjectCol"] as! RLMObject)["anyCol"] as! String == "string")
  }
}
