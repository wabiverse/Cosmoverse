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
import RealmSwift
import XCTest

// swiftlint:disable cyclomatic_complexity

class PrimitiveMapTestsBase<O: ObjectFactory, V: MapValueFactory>: TestCase
{
  var realm: Realm?
  var obj: V.MapRoot!
  var obj2: V.MapRoot!
  var map: Map<String, V>!
  var otherMap: Map<String, V>!
  var values: [(key: String, value: V)]!

  override func setUp()
  {
    obj = O.get()
    obj2 = O.get()
    realm = obj.realm
    map = obj[keyPath: V.map]
    otherMap = obj2[keyPath: V.map]
    values = V.values().enumerated().map { (key: "key\($0)", value: $1) }
  }

  override func tearDown()
  {
    realm?.cancelWrite()
    realm = nil
    map = nil
    otherMap = nil
    obj = nil
    obj2 = nil
  }
}

class PrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V>
{
  func testInvalidated()
  {
    XCTAssertFalse(map.isInvalidated)
    if let realm = obj.realm
    {
      realm.delete(obj)
      XCTAssertTrue(map.isInvalidated)
    }
  }

  func testEnumeration()
  {
    XCTAssertEqual(0, map.count)
    map.merge(values) { $1 }
    let exp = expectation(description: "did enumerate all keys and values")
    exp.expectedFulfillmentCount = 3
    for element in map where values.filter({ $0.key == element.key }).first!.value == element.value
    {
      exp.fulfill()
    }
    waitForExpectations(timeout: 1.0, handler: nil)
  }

  func testValueForKey()
  {
    let key = values[0].key
    XCTAssertNil(map.value(forKey: key))
    map.setValue(values[0].value, forKey: key)
    let kvc: AnyObject = map.value(forKey: key)!
    XCTAssertEqual(dynamicBridgeCast(fromObjectiveC: kvc) as V, values[0].value)
  }

  func testInsert()
  {
    XCTAssertEqual(0, map.count)

    map[values[0].key] = values[0].value
    XCTAssertEqual(1, map.count)
    XCTAssertEqual(1, map.keys.count)
    XCTAssertEqual(1, map.values.count)
    XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
    XCTAssertEqual(map[values[0].key], values[0].value)

    map[values[1].key] = values[1].value
    XCTAssertEqual(2, map.count)
    XCTAssertEqual(2, map.keys.count)
    XCTAssertEqual(2, map.values.count)
    XCTAssertTrue(Set([values[0].key, values[1].key]).isSubset(of: map.keys))
    XCTAssertEqual(map[values[1].key], values[1].value)

    map[values[2].key] = values[2].value
    XCTAssertEqual(3, map.count)
    XCTAssertEqual(3, map.keys.count)
    XCTAssertEqual(3, map.values.count)
    XCTAssertTrue(Set(values.map(\.key)).isSubset(of: map.keys))
    XCTAssertEqual(map[values[2].key], values[2].value)
  }

  func testUpdate()
  {
    XCTAssertEqual(0, map.count)

    map[values[0].key] = values[0].value
    XCTAssertEqual(1, map.count)
    XCTAssertEqual(1, map.keys.count)
    XCTAssertEqual(1, map.values.count)
    XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
    XCTAssertEqual(map[values[0].key], values[0].value)

    map.updateValue(values[1].value, forKey: values[0].key)
    XCTAssertEqual(1, map.count)
    XCTAssertEqual(1, map.keys.count)
    XCTAssertEqual(1, map.values.count)
    XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
    XCTAssertEqual(map[values[0].key], values[1].value)
  }

  func testRemove()
  {
    XCTAssertEqual(0, map.count)
    map.merge(values) { $1 }
    XCTAssertEqual(3, map.count)
    XCTAssertEqual(3, map.keys.count)
    XCTAssertEqual(3, map.values.count)
    XCTAssertTrue(Set(values.map(\.key)).isSubset(of: map.keys))

    let key = values[0].key
    map.setValue(nil, forKey: key)
    XCTAssertNil(map.value(forKey: key))

    map.removeAll()
    XCTAssertEqual(0, map.count)

    map.merge(values) { $1 }

    map[values[1].key] = nil
    XCTAssertNil(map[values[1].key])
    map.removeObject(for: values[2].key)
    // make sure the key was deleted
    XCTAssertTrue(Set([values[0].key]).isSubset(of: map.keys))
  }

  func testSubscript()
  {
    // setter
    XCTAssertEqual(0, map.count)
    map[values[0].key] = values[0].value
    map[values[1].key] = values[1].value
    map[values[2].key] = values[2].value
    XCTAssertEqual(3, map.count)
    XCTAssertEqual(3, map.keys.count)
    XCTAssertEqual(3, map.values.count)
    XCTAssertTrue(Set(values.map(\.key)).isSubset(of: map.keys))
    map[values[0].key] = values[0].value
    map[values[1].key] = nil
    map[values[2].key] = values[2].value
    XCTAssertEqual(2, map.count)
    XCTAssertEqual(2, map.keys.count)
    XCTAssertEqual(2, map.values.count)
    XCTAssertTrue(Set([values[0].key, values[2].key]).isSubset(of: map.keys))
    XCTAssertEqual(2, map.count)
    XCTAssertEqual(2, map.keys.count)
    XCTAssertEqual(2, map.values.count)
    XCTAssertTrue(Set([values[0].key, values[2].key]).isSubset(of: map.keys))
    // getter
    map.removeAll()
    XCTAssertNil(map[values[0].key])
    map[values[0].key] = values[0].value
    XCTAssertEqual(values[0].value, map[values[0].key])
  }

  func testObjectForKey()
  {
    XCTAssertEqual(0, map.count)
    map[values[0].key] = values[0].value
    XCTAssertEqual(values[0].value, dynamicBridgeCast(fromObjectiveC: map.object(forKey: values[0].key as AnyObject)!) as V)
  }
}

class MinMaxPrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.PersistedType: MinMaxType
{
  func testMin()
  {
    XCTAssertNil(map.min())
    map.merge(values) { $1 }
    map.merge(values) { $1 }
    XCTAssertEqual(map.min(), V.min())
  }

  func testMax()
  {
    XCTAssertNil(map.max())
    map.merge(values) { $1 }
    XCTAssertEqual(map.max(), V.max())
  }
}

class AddablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V: NumericValueFactory, V.PersistedType: AddableType
{
  func testSum()
  {
    XCTAssertEqual(map.sum(), .zero)
    map.merge(values) { $1 }
    XCTAssertEqual(V.doubleValue(map.sum()), V.sum(), accuracy: 0.01)
  }

  func testAverage()
  {
    XCTAssertNil(map.average() as V.AverageType?)
    map.merge(values) { $1 }
    XCTAssertEqual(V.doubleValue(map.average()!), V.average(), accuracy: 0.1)
  }
}

class SortablePrimitiveMapTests<O: ObjectFactory, V: MapValueFactory>: PrimitiveMapTestsBase<O, V> where V.PersistedType: SortableType
{
  func testSorted()
  {
    map.merge(values) { $1 }
    XCTAssertEqual(map.count, 3)
    let values2: [V] = values.map(\.value)

    assertEqual(values2, Array(map.sorted()))
    assertEqual(values2, Array(map.sorted(ascending: true)))
    assertEqual(values2.reversed(), Array(map.sorted(ascending: false)))
  }
}

func addPrimitiveMapTests<OF: ObjectFactory>(_ suite: XCTestSuite, _: OF.Type)
{
  PrimitiveMapTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Bool>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, String>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Data>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, ObjectId>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, UUID>.defaultTestSuite.tests.forEach(suite.addTest)

  MinMaxPrimitiveMapTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Date>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

  AddablePrimitiveMapTests<OF, Int>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Float>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Double>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Decimal128>.defaultTestSuite.tests.forEach(suite.addTest)

  PrimitiveMapTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Bool?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, String?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Data?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, ObjectId?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, UUID?>.defaultTestSuite.tests.forEach(suite.addTest)

  MinMaxPrimitiveMapTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

  AddablePrimitiveMapTests<OF, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
  AddablePrimitiveMapTests<OF, Decimal128?>.defaultTestSuite.tests.forEach(suite.addTest)

  PrimitiveMapTests<OF, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

  MinMaxPrimitiveMapTests<OF, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)

  PrimitiveMapTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
  PrimitiveMapTests<OF, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

  MinMaxPrimitiveMapTests<OF, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
  MinMaxPrimitiveMapTests<OF, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
}

class UnmanagedPrimitiveMapTests: TestCase
{
  override class var defaultTestSuite: XCTestSuite
  {
    let suite = XCTestSuite(name: "Unmanaged Primitive Maps")
    addPrimitiveMapTests(suite, UnmanagedObjectFactory.self)
    return suite
  }
}

class ManagedPrimitiveMapTests: TestCase
{
  override class var defaultTestSuite: XCTestSuite
  {
    let suite = XCTestSuite(name: "Managed Primitive Maps")
    addPrimitiveMapTests(suite, ManagedObjectFactory.self)

    SortablePrimitiveMapTests<ManagedObjectFactory, Int>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int8>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int16>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int32>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int64>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Float>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Double>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, String>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Date>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Data>.defaultTestSuite.tests.forEach(suite.addTest)

    SortablePrimitiveMapTests<ManagedObjectFactory, Int?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int8?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int16?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int32?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Int64?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Float?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Double?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, String?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Date?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, Data?>.defaultTestSuite.tests.forEach(suite.addTest)

    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt8>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt16>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt32>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt64>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumFloat>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumDouble>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumString>.defaultTestSuite.tests.forEach(suite.addTest)

    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt8?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt16?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt32?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumInt64?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumFloat?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumDouble?>.defaultTestSuite.tests.forEach(suite.addTest)
    SortablePrimitiveMapTests<ManagedObjectFactory, EnumString?>.defaultTestSuite.tests.forEach(suite.addTest)

    return suite
  }
}
