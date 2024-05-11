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
import XCTest

private var dynamicDefaultSeed = 0
private func nextDynamicDefaultSeed() -> Int
{
  dynamicDefaultSeed += 1
  return dynamicDefaultSeed
}

class ModernDynamicDefaultObject: Object
{
  @Persisted(primaryKey: true) var intCol = nextDynamicDefaultSeed()
  @Persisted var floatCol = Float(nextDynamicDefaultSeed())
  @Persisted var doubleCol = Double(nextDynamicDefaultSeed())
  @Persisted var dateCol = Date(timeIntervalSinceReferenceDate: TimeInterval(nextDynamicDefaultSeed()))
  @Persisted var stringCol = UUID().uuidString
  @Persisted var binaryCol = UUID().uuidString.data(using: .utf8)
}

class ModernObjectTests: TestCase
{
  // init() Tests are in ObjectCreationTests.swift
  // init(value:) tests are in ObjectCreationTests.swift

  func testObjectSchema()
  {
    let object = ModernAllTypesObject()
    let schema = object.objectSchema
    XCTAssert(schema as AnyObject is ObjectSchema)
    XCTAssert(schema.properties as AnyObject is [Property])
    XCTAssertEqual(schema.className, "ModernAllTypesObject")
    XCTAssertEqual(schema.properties.map(\.name),
                   ["pk", "boolCol", "intCol", "int8Col", "int16Col",
                    "int32Col", "int64Col", "floatCol", "doubleCol",
                    "stringCol", "binaryCol", "dateCol", "decimalCol",
                    "objectIdCol", "objectCol", "arrayCol", "setCol", "mapCol",
                    "anyCol", "uuidCol", "intEnumCol", "stringEnumCol",
                    "optIntCol", "optInt8Col", "optInt16Col",
                    "optInt32Col", "optInt64Col", "optFloatCol",
                    "optDoubleCol", "optBoolCol", "optStringCol",
                    "optBinaryCol", "optDateCol", "optDecimalCol",
                    "optObjectIdCol", "optUuidCol", "optIntEnumCol",
                    "optStringEnumCol", "arrayBool", "arrayInt",
                    "arrayInt8", "arrayInt16", "arrayInt32",
                    "arrayInt64", "arrayFloat", "arrayDouble",
                    "arrayString", "arrayBinary", "arrayDate",
                    "arrayDecimal", "arrayObjectId", "arrayAny",
                    "arrayUuid", "arrayOptBool", "arrayOptInt",
                    "arrayOptInt8", "arrayOptInt16", "arrayOptInt32",
                    "arrayOptInt64", "arrayOptFloat", "arrayOptDouble",
                    "arrayOptString", "arrayOptBinary", "arrayOptDate",
                    "arrayOptDecimal", "arrayOptObjectId",
                    "arrayOptUuid", "setBool", "setInt", "setInt8",
                    "setInt16", "setInt32", "setInt64", "setFloat",
                    "setDouble", "setString", "setBinary", "setDate",
                    "setDecimal", "setObjectId", "setAny", "setUuid",
                    "setOptBool", "setOptInt", "setOptInt8",
                    "setOptInt16", "setOptInt32", "setOptInt64",
                    "setOptFloat", "setOptDouble", "setOptString",
                    "setOptBinary", "setOptDate", "setOptDecimal",
                    "setOptObjectId", "setOptUuid", "mapBool", "mapInt",
                    "mapInt8", "mapInt16", "mapInt32", "mapInt64",
                    "mapFloat", "mapDouble", "mapString", "mapBinary",
                    "mapDate", "mapDecimal", "mapObjectId", "mapAny",
                    "mapUuid", "mapOptBool", "mapOptInt", "mapOptInt8",
                    "mapOptInt16", "mapOptInt32", "mapOptInt64",
                    "mapOptFloat", "mapOptDouble", "mapOptString",
                    "mapOptBinary", "mapOptDate", "mapOptDecimal",
                    "mapOptObjectId", "mapOptUuid"])
  }

  func testObjectSchemaForObjectWithConvenienceInitializer()
  {
    let object = ModernConvenienceInitializerObject(stringCol: "abc")
    let schema = object.objectSchema
    XCTAssert(schema as AnyObject is ObjectSchema)
    XCTAssert(schema.properties as AnyObject is [Property])
    XCTAssertEqual(schema.className, "ModernConvenienceInitializerObject")
    XCTAssertEqual(schema.properties.map(\.name), ["stringCol"])
  }

  func testCannotUpdatePrimaryKey()
  {
    let primaryKeyReason = "Primary key can't be changed.* after an object is inserted."
    let realm = realmWithTestPath()
    realm.beginWrite()

    func test<O: ModernPrimaryKeyObject>(_ object: O, _ v1: O.PrimaryKey, _ v2: O.PrimaryKey)
    {
      // Unmanaged objects can mutate the primary key
      object.pk = v1
      XCTAssertEqual(object.pk, v1)
      object.pk = v2
      XCTAssertEqual(object.pk, v2)
      object["pk"] = v1
      XCTAssertEqual(object.pk, v1)
      object.setValue(v2, forKey: "pk")
      XCTAssertEqual(object.pk, v2)

      // Managed objects cannot mutate the pk
      realm.add(object)
      assertThrows(object.pk = v2, reasonMatching: primaryKeyReason)
      assertThrows(object["pk"] = v2, reasonMatching: primaryKeyReason)
      assertThrows(object.setValue(v2, forKey: "pk"), reasonMatching: primaryKeyReason)
    }

    test(ModernPrimaryIntObject(), 1, 2)
    test(ModernPrimaryInt8Object(), 1, 2)
    test(ModernPrimaryInt16Object(), 1, 2)
    test(ModernPrimaryInt32Object(), 1, 2)
    test(ModernPrimaryInt64Object(), 1, 2)
    test(ModernPrimaryOptionalIntObject(), 1, nil)
    test(ModernPrimaryOptionalInt8Object(), 1, nil)
    test(ModernPrimaryOptionalInt16Object(), 1, nil)
    test(ModernPrimaryOptionalInt32Object(), 1, nil)
    test(ModernPrimaryOptionalInt64Object(), 1, nil)

    test(ModernPrimaryStringObject(), "a", "b")
    test(ModernPrimaryOptionalStringObject(), "a", nil)
    test(ModernPrimaryUUIDObject(), UUID(), UUID())
    test(ModernPrimaryOptionalUUIDObject(), UUID(), nil)
    test(ModernPrimaryObjectIdObject(), ObjectId.generate(), ObjectId.generate())
    test(ModernPrimaryOptionalObjectIdObject(), ObjectId.generate(), nil)

    test(ModernPrimaryIntEnumObject(), .value1, .value2)
    test(ModernPrimaryOptionalIntEnumObject(), .value1, nil)

    realm.cancelWrite()
  }

  func testDynamicDefaultPropertyValues()
  {
    func assertDifferentPropertyValues(_ obj1: ModernDynamicDefaultObject, _ obj2: ModernDynamicDefaultObject)
    {
      XCTAssertNotEqual(obj1.intCol, obj2.intCol)
      XCTAssertNotEqual(obj1.floatCol, obj2.floatCol)
      XCTAssertNotEqual(obj1.doubleCol, obj2.doubleCol)
      XCTAssertNotEqual(obj1.dateCol.timeIntervalSinceReferenceDate, obj2.dateCol.timeIntervalSinceReferenceDate,
                        accuracy: 0.01)
      XCTAssertNotEqual(obj1.stringCol, obj2.stringCol)
      XCTAssertNotEqual(obj1.binaryCol, obj2.binaryCol)
    }
    assertDifferentPropertyValues(ModernDynamicDefaultObject(), ModernDynamicDefaultObject())
    let realm = try! Realm()
    try! realm.write
    {
      assertDifferentPropertyValues(realm.create(ModernDynamicDefaultObject.self),
                                    realm.create(ModernDynamicDefaultObject.self))
    }
  }

  func testWillSetDidSet()
  {
    let obj = SetterObservers()
    var calls = 0
    obj.willSetCallback = {
      XCTAssertEqual(obj.value, 0)
      calls += 1
    }
    obj.didSetCallback = {
      XCTAssertEqual(obj.value, 1)
      calls += 1
    }
    obj.value = 1
    XCTAssertEqual(calls, 2)

    let realm = try! Realm()
    realm.beginWrite()
    realm.add(obj)

    obj.willSetCallback = {
      XCTAssertEqual(obj.value, 1)
      calls += 1
    }
    obj.didSetCallback = {
      XCTAssertEqual(obj.value, 2)
      calls += 1
    }
    obj.value = 2
    XCTAssertEqual(calls, 4)

    realm.cancelWrite()

    // The callbacks form a circular reference and so need to be removed
    obj.willSetCallback = nil
    obj.didSetCallback = nil
  }

  func testAddingObjectReusesExistingCollectionObjects()
  {
    let obj = ModernAllTypesObject()
    let list = obj.arrayCol
    let set = obj.setCol
    let dictionary = obj.mapAny

    XCTAssertNil(list.realm)
    XCTAssertNil(set.realm)
    XCTAssertNil(dictionary.realm)
    XCTAssertTrue(list === obj.arrayCol)
    XCTAssertTrue(set === obj.setCol)
    XCTAssertTrue(dictionary === obj.mapAny)

    let realm = try! Realm()
    try! realm.write
    {
      realm.add(obj)
    }

    XCTAssertNotNil(list.realm)
    XCTAssertNotNil(set.realm)
    XCTAssertNotNil(dictionary.realm)
    XCTAssertTrue(list === obj.arrayCol)
    XCTAssertTrue(set === obj.setCol)
    XCTAssertTrue(dictionary === obj.mapAny)
  }

  func testAddingPreviouslyObservedObjectReusesExistingCollectionObjects()
  {
    let obj = ModernAllTypesObject()
    let list = obj.arrayCol
    let set = obj.setCol
    let dictionary = obj.mapAny

    // We don't allow adding an object with active observers to the Realm
    // (it causes problems with the subclass KVO creates at runtime), but
    // once a property has been observed it stays in the observed state forever.
    obj.addObserver(self, forKeyPath: "arrayCol", context: nil)
    obj.addObserver(self, forKeyPath: "setCol", context: nil)
    obj.addObserver(self, forKeyPath: "mapAny", context: nil)
    obj.removeObserver(self, forKeyPath: "arrayCol", context: nil)
    obj.removeObserver(self, forKeyPath: "setCol", context: nil)
    obj.removeObserver(self, forKeyPath: "mapAny", context: nil)

    XCTAssertNil(list.realm)
    XCTAssertNil(set.realm)
    XCTAssertNil(dictionary.realm)
    XCTAssertTrue(list === obj.arrayCol)
    XCTAssertTrue(set === obj.setCol)
    XCTAssertTrue(dictionary === obj.mapAny)

    let realm = try! Realm()
    try! realm.write
    {
      realm.add(obj)
    }

    XCTAssertNotNil(list.realm)
    XCTAssertNotNil(set.realm)
    XCTAssertNotNil(dictionary.realm)
    XCTAssertTrue(list === obj.arrayCol)
    XCTAssertTrue(set === obj.setCol)
    XCTAssertTrue(dictionary === obj.mapAny)
  }
}
