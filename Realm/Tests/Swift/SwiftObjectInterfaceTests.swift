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
import XCTest

#if canImport(RealmTestSupport)
  import RealmTestSupport
#endif

enum OuterClass
{
  class InnerClass
  {}
}

class SwiftRLMStringObjectSubclass: SwiftRLMStringObject
{
  @objc dynamic var stringCol2 = ""
}

class SwiftRLMSelfRefrencingSubclass: SwiftRLMStringObject
{
  @objc dynamic var objects = RLMArray<SwiftRLMSelfRefrencingSubclass>(objectClassName: SwiftRLMSelfRefrencingSubclass.className())
  @objc dynamic var objectSet = RLMSet<SwiftRLMSelfRefrencingSubclass>(objectClassName: SwiftRLMSelfRefrencingSubclass.className())
}

class SwiftRLMDefaultObject: RLMObject
{
  @objc dynamic var intCol = 1
  @objc dynamic var boolCol = true

  override class func defaultPropertyValues() -> [AnyHashable: Any]?
  {
    ["intCol": 2]
  }
}

class SwiftRLMOptionalNumberObject: RLMObject
{
  @objc dynamic var intCol: NSNumber? = 1
  @objc dynamic var floatCol: NSNumber? = 2.2 as Float as NSNumber
  @objc dynamic var doubleCol: NSNumber? = 3.3
  @objc dynamic var boolCol: NSNumber? = true
}

class SwiftRLMObjectInterfaceTests: RLMTestCase
{
  // Swift models

  func testSwiftRLMObject()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()

    let obj = SwiftRLMObject()
    realm.add(obj)

    obj.boolCol = true
    obj.intCol = 1234
    obj.floatCol = 1.1
    obj.doubleCol = 2.2
    obj.stringCol = "abcd"
    obj.binaryCol = "abcd".data(using: String.Encoding.utf8)
    obj.dateCol = Date(timeIntervalSince1970: 123)
    obj.objectCol = SwiftRLMBoolObject()
    obj.objectCol.boolCol = true
    obj.arrayCol.add(obj.objectCol)
    obj.setCol.add(obj.objectCol)
    obj.uuidCol = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    obj.rlmValue = NSString("I am a mixed value")
    try! realm.commitWriteTransaction()

    let data = "abcd".data(using: String.Encoding.utf8)

    let firstObj = SwiftRLMObject.allObjects(in: realm).firstObject() as! SwiftRLMObject
    XCTAssertEqual(firstObj.boolCol, true, "should be true")
    XCTAssertEqual(firstObj.intCol, 1234, "should be 1234")
    XCTAssertEqual(firstObj.floatCol, Float(1.1), "should be 1.1")
    XCTAssertEqual(firstObj.doubleCol, 2.2, "should be 2.2")
    XCTAssertEqual(firstObj.stringCol, "abcd", "should be abcd")
    XCTAssertEqual(firstObj.binaryCol!, data!)
    XCTAssertEqual(firstObj.dateCol, Date(timeIntervalSince1970: 123), "should be epoch + 123")
    XCTAssertEqual(firstObj.objectCol.boolCol, true, "should be true")
    XCTAssertEqual(firstObj.uuidCol?.uuidString, "00000000-0000-0000-0000-000000000000")
    XCTAssertEqual(firstObj.rlmValue as! NSString, NSString("I am a mixed value"))
    XCTAssertEqual(obj.arrayCol.count, UInt(1), "array count should be 1")
    XCTAssertEqual(obj.arrayCol.firstObject()!.boolCol, true, "should be true")
    XCTAssertEqual(obj.setCol.count, UInt(1), "set count should be 1")
    XCTAssertEqual(obj.setCol.allObjects[0].boolCol, true, "should be true")
  }

  func testDefaultValueSwiftRLMObject()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    realm.add(SwiftRLMObject())
    try! realm.commitWriteTransaction()

    let data = "a".data(using: String.Encoding.utf8)

    let firstObj = SwiftRLMObject.allObjects(in: realm).firstObject() as! SwiftRLMObject
    XCTAssertEqual(firstObj.boolCol, false, "should be false")
    XCTAssertEqual(firstObj.intCol, 123, "should be 123")
    XCTAssertEqual(firstObj.floatCol, Float(1.23), "should be 1.23")
    XCTAssertEqual(firstObj.doubleCol, 12.3, "should be 12.3")
    XCTAssertEqual(firstObj.stringCol, "a", "should be a")
    XCTAssertEqual(firstObj.binaryCol!, data!)
    XCTAssertEqual(firstObj.dateCol, Date(timeIntervalSince1970: 1), "should be epoch + 1")
    XCTAssertEqual(firstObj.objectCol.boolCol, false, "should be false")
    XCTAssertEqual(firstObj.arrayCol.count, UInt(0), "array count should be zero")
    XCTAssertEqual(firstObj.setCol.count, UInt(0), "set count should be zero")
    XCTAssertEqual(firstObj.uuidCol!.uuidString, "00000000-0000-0000-0000-000000000000")
    XCTAssertEqual(firstObj.uuidCol!.uuidString, "00000000-0000-0000-0000-000000000000")
    XCTAssertEqual(firstObj.rlmValue as! NSString, NSString("A Mixed Object"))
  }

  func testMergedDefaultValuesSwiftRLMObject()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = SwiftRLMDefaultObject.create(in: realm, withValue: NSDictionary())
    try! realm.commitWriteTransaction()

    let object = SwiftRLMDefaultObject.allObjects(in: realm).firstObject() as! SwiftRLMDefaultObject
    XCTAssertEqual(object.intCol, 2, "defaultPropertyValues should override native property default value")
    XCTAssertEqual(object.boolCol, true, "native property default value should be used if defaultPropertyValues doesn't contain that key")
  }

  func testSubclass()
  {
    // test className methods
    XCTAssertEqual("SwiftRLMStringObject", SwiftRLMStringObject.className())
    XCTAssertEqual("SwiftRLMStringObjectSubclass", SwiftRLMStringObjectSubclass.className())

    let realm = RLMRealm.default()
    realm.beginWriteTransaction()
    _ = SwiftRLMStringObject.createInDefaultRealm(withValue: ["string"])

    _ = SwiftRLMStringObjectSubclass.createInDefaultRealm(withValue: ["string", "string2"])
    try! realm.commitWriteTransaction()

    // ensure creation in proper table
    XCTAssertEqual(UInt(1), SwiftRLMStringObjectSubclass.allObjects().count)
    XCTAssertEqual(UInt(1), SwiftRLMStringObject.allObjects().count)

    try! realm.transaction
    {
      // create self referencing subclass
      let sub = SwiftRLMSelfRefrencingSubclass.createInDefaultRealm(withValue: ["string"])
      let sub2 = SwiftRLMSelfRefrencingSubclass()
      sub.objects.add(sub2)
      sub.objectSet.add(sub2)
    }
  }

  func testOptionalNSNumberProperties()
  {
    let realm = realmWithTestPath()
    let no = SwiftRLMOptionalNumberObject()
    XCTAssertEqual([.int, .float, .double, .bool], no.objectSchema.properties.map(\.type))

    XCTAssertEqual(1, no.intCol!)
    XCTAssertEqual(2.2 as Float as NSNumber, no.floatCol!)
    XCTAssertEqual(3.3, no.doubleCol!)
    XCTAssertEqual(true, no.boolCol!)

    try! realm.transaction
    {
      realm.add(no)
      no.intCol = nil
      no.floatCol = nil
      no.doubleCol = nil
      no.boolCol = nil
    }

    XCTAssertNil(no.intCol)
    XCTAssertNil(no.floatCol)
    XCTAssertNil(no.doubleCol)
    XCTAssertNil(no.boolCol)

    try! realm.transaction
    {
      no.intCol = 1.1
      no.floatCol = 2.2 as Float as NSNumber
      no.doubleCol = 3.3
      no.boolCol = false
    }

    XCTAssertEqual(1, no.intCol!)
    XCTAssertEqual(2.2 as Float as NSNumber, no.floatCol!)
    XCTAssertEqual(3.3, no.doubleCol!)
    XCTAssertEqual(false, no.boolCol!)
  }

  func testOptionalSwiftRLMProperties()
  {
    let realm = realmWithTestPath()
    try! realm.transaction { realm.add(SwiftRLMOptionalObject()) }

    let firstObj = SwiftRLMOptionalObject.allObjects(in: realm).firstObject() as! SwiftRLMOptionalObject
    XCTAssertNil(firstObj.optObjectCol)
    XCTAssertNil(firstObj.optStringCol)
    XCTAssertNil(firstObj.optNSStringCol)
    XCTAssertNil(firstObj.optBinaryCol)
    XCTAssertNil(firstObj.optDateCol)
    XCTAssertNil(firstObj.uuidCol)

    try! realm.transaction
    {
      firstObj.optObjectCol = SwiftRLMBoolObject()
      firstObj.optObjectCol!.boolCol = true

      firstObj.optStringCol = "Hi!"
      firstObj.optNSStringCol = "Hi!"
      firstObj.optBinaryCol = Data(bytes: "hi", count: 2)
      firstObj.optDateCol = Date(timeIntervalSinceReferenceDate: 10)
      firstObj.uuidCol = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    }
    XCTAssertTrue(firstObj.optObjectCol!.boolCol)
    XCTAssertEqual(firstObj.optStringCol!, "Hi!")
    XCTAssertEqual(firstObj.optNSStringCol!, "Hi!")
    XCTAssertEqual(firstObj.optBinaryCol!, Data(bytes: "hi", count: 2))
    XCTAssertEqual(firstObj.optDateCol!, Date(timeIntervalSinceReferenceDate: 10))
    XCTAssertEqual(firstObj.uuidCol!.uuidString, "00000000-0000-0000-0000-000000000000")

    try! realm.transaction
    {
      firstObj.optObjectCol = nil
      firstObj.optStringCol = nil
      firstObj.optNSStringCol = nil
      firstObj.optBinaryCol = nil
      firstObj.optDateCol = nil
      firstObj.uuidCol = nil
    }
    XCTAssertNil(firstObj.optObjectCol)
    XCTAssertNil(firstObj.optStringCol)
    XCTAssertNil(firstObj.optNSStringCol)
    XCTAssertNil(firstObj.optBinaryCol)
    XCTAssertNil(firstObj.optDateCol)
    XCTAssertNil(firstObj.uuidCol)
  }

  func testSwiftRLMClassNameIsDemangled()
  {
    XCTAssertEqual(SwiftRLMObject.className(), "SwiftRLMObject",
                   "Calling className() on Swift class should return demangled name")
  }

  func testPrimitiveArray()
  {
    let obj = SwiftRLMPrimitiveArrayObject()
    let str = "str" as NSString
    let data = "str".data(using: .utf8)! as Data as NSData
    let date = NSDate()
    let str2 = "str2" as NSString
    let data2 = "str2".data(using: .utf8)! as Data as NSData
    let date2 = NSDate(timeIntervalSince1970: 0)

    obj.stringCol.add(str)
    XCTAssertEqual(obj.stringCol[0], str)
    XCTAssertEqual(obj.stringCol.index(of: str), 0)
    XCTAssertEqual(obj.stringCol.index(of: str2), UInt(NSNotFound))

    obj.dataCol.add(data)
    XCTAssertEqual(obj.dataCol[0], data)
    XCTAssertEqual(obj.dataCol.index(of: data), 0)
    XCTAssertEqual(obj.dataCol.index(of: data2), UInt(NSNotFound))

    obj.dateCol.add(date)
    XCTAssertEqual(obj.dateCol[0], date)
    XCTAssertEqual(obj.dateCol.index(of: date), 0)
    XCTAssertEqual(obj.dateCol.index(of: date2), UInt(NSNotFound))

    obj.optStringCol.add(str)
    XCTAssertEqual(obj.optStringCol[0], str)
    obj.optDataCol.add(data)
    XCTAssertEqual(obj.optDataCol[0], data)
    obj.optDateCol.add(date)
    XCTAssertEqual(obj.optDateCol[0], date)

    obj.optStringCol.add(NSNull())
    XCTAssertEqual(obj.optStringCol[1], NSNull())
    obj.optDataCol.add(NSNull())
    XCTAssertEqual(obj.optDataCol[1], NSNull())
    obj.optDateCol.add(NSNull())
    XCTAssertEqual(obj.optDateCol[1], NSNull())

    assertThrowsWithReasonMatching(obj.optDataCol.add(str), ".*")
  }

  func testPrimitiveSet()
  {
    let obj = SwiftRLMPrimitiveSetObject()
    let str = "str" as NSString
    let data = "str".data(using: .utf8)! as Data as NSData
    let date = NSDate()
    obj.stringCol.add(str)
    XCTAssertTrue(obj.stringCol.contains(str))

    obj.dataCol.add(data)
    XCTAssertTrue(obj.dataCol.contains(data))

    obj.dateCol.add(date)
    XCTAssertTrue(obj.dateCol.contains(date))

    obj.optStringCol.add(str)
    XCTAssertTrue(obj.optStringCol.contains(str))
    obj.optDataCol.add(data)
    XCTAssertTrue(obj.optDataCol.contains(data))
    obj.optDateCol.add(date)
    XCTAssertTrue(obj.optDateCol.contains(date))

    obj.optStringCol.add(NSNull())
    XCTAssertTrue(obj.optStringCol.contains(NSNull()))
    obj.optDataCol.add(NSNull())
    XCTAssertTrue(obj.optDataCol.contains(NSNull()))
    obj.optDateCol.add(NSNull())
    XCTAssertTrue(obj.optDateCol.contains(NSNull()))

    assertThrowsWithReasonMatching(obj.optDataCol.add(str), ".*")
  }

  func testUuidPrimitiveArray()
  {
    let obj = SwiftRLMPrimitiveArrayObject()
    let uuidA = NSUUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    let uuidB = NSUUID(uuidString: "137DECC8-B300-4954-A233-F89909F4FD89")!

    obj.uuidCol.add(uuidA)
    XCTAssertEqual(obj.uuidCol[0], uuidA)
    XCTAssertEqual(obj.uuidCol.index(of: uuidA), 0)
    XCTAssertEqual(obj.uuidCol.index(of: uuidB), UInt(NSNotFound))

    obj.optUuidCol.add(NSNull())
    XCTAssertEqual(obj.optUuidCol[0], NSNull())
    obj.optUuidCol.add(uuidA)
    XCTAssertEqual(obj.optUuidCol[1], uuidA)
    obj.optUuidCol.add(NSNull())
    XCTAssertEqual(obj.optUuidCol[2], NSNull())
  }

  func testUuidPrimitiveSet()
  {
    let obj = SwiftRLMPrimitiveSetObject()
    let uuidA = NSUUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    obj.uuidCol.add(uuidA)
    XCTAssertTrue(obj.uuidCol.contains(uuidA))

    obj.optUuidCol.add(NSNull())
    XCTAssertTrue(obj.optUuidCol.contains(NSNull()))
    obj.optUuidCol.add(uuidA)
    XCTAssertTrue(obj.optUuidCol.contains(uuidA))
    obj.optUuidCol.add(NSNull())
    XCTAssertTrue(obj.optUuidCol.contains(NSNull()))
  }

  // Objective-C models

  /// Note: Swift doesn't support custom accessor names
  /// so we test to make sure models with custom accessors can still be accessed
  func testCustomAccessors()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    let ca = CustomAccessorsObject.create(in: realm, withValue: ["name", 2])
    XCTAssertEqual(ca.name!, "name", "name property should be name.")
    ca.age = 99
    XCTAssertEqual(ca.age, Int32(99), "age property should be 99")
    try! realm.commitWriteTransaction()
  }

  func testClassExtension()
  {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()
    let bObject = BaseClassStringObject()
    bObject.intCol = 1
    bObject.stringCol = "stringVal"
    realm.add(bObject)
    try! realm.commitWriteTransaction()

    let objectFromRealm = BaseClassStringObject.allObjects(in: realm)[0] as! BaseClassStringObject
    XCTAssertEqual(objectFromRealm.intCol, Int32(1), "Should be 1")
    XCTAssertEqual(objectFromRealm.stringCol!, "stringVal", "Should be stringVal")
  }

  func testCreateOrUpdate()
  {
    let realm = RLMRealm.default()
    realm.beginWriteTransaction()
    SwiftRLMPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string", 1])
    let objects = SwiftRLMPrimaryStringObject.allObjects() as! RLMResults<SwiftRLMPrimaryStringObject>
    XCTAssertEqual(objects.count, UInt(1), "Should have 1 object")
    XCTAssertEqual(objects[0].intCol, 1, "Value should be 1")

    SwiftRLMPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string2", 2])
    XCTAssertEqual(objects.count, UInt(2), "Should have 2 objects")

    SwiftRLMPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string", 3])
    XCTAssertEqual(objects.count, UInt(2), "Should have 2 objects")
    XCTAssertEqual(objects[0].intCol, 3, "Value should be 3")

    try! realm.commitWriteTransaction()
  }

  func testObjectForPrimaryKey()
  {
    let realm = RLMRealm.default()
    realm.beginWriteTransaction()
    SwiftRLMPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string", 1])

    let obj = SwiftRLMPrimaryStringObject.object(forPrimaryKey: "string")
    XCTAssertNotNil(obj!)
    XCTAssertEqual(obj!.intCol, 1)

    realm.cancelWriteTransaction()
  }

  /// if this fails (and you haven't changed the test module name), the checks
  /// for swift class names and the demangling logic need to be updated
  func testNSStringFromClassDemangledTopLevelClassNames()
  {
    #if SWIFT_PACKAGE
      XCTAssertEqual(NSStringFromClass(OuterClass.self), "RealmObjcSwiftTests.OuterClass")
    #else
      XCTAssertEqual(NSStringFromClass(OuterClass.self), "Tests.OuterClass")
    #endif
  }

  /// if this fails (and you haven't changed the test module name), the prefix
  /// check in RLMSchema initialization needs to be updated
  func testNestedClassNameMangling()
  {
    #if SWIFT_PACKAGE
      XCTAssertEqual(NSStringFromClass(OuterClass.InnerClass.self), "_TtCC19RealmObjcSwiftTests10OuterClass10InnerClass")
    #else
      XCTAssertEqual(NSStringFromClass(OuterClass.InnerClass.self), "_TtCC5Tests10OuterClass10InnerClass")
    #endif
  }
}
