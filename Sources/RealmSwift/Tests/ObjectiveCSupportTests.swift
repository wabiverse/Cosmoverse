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
import RealmSwift
import XCTest

class ObjectiveCSupportTests: TestCase
{
  func testSupport()
  {
    let realm = try! Realm()

    try! realm.write
    {
      realm.add(SwiftObject())
    }

    let results = realm.objects(SwiftObject.self)
    let rlmResults = ObjectiveCSupport.convert(object: results)
    XCTAssert(rlmResults.isKind(of: RLMResults<AnyObject>.self))
    XCTAssertEqual(rlmResults.count, 1)
    XCTAssertEqual(unsafeBitCast(rlmResults.firstObject(), to: SwiftObject.self).intCol, 123)

    let list = List<SwiftObject>()
    list.append(SwiftObject())
    let rlmArray = ObjectiveCSupport.convert(object: list)
    XCTAssert(rlmArray.isKind(of: RLMArray<AnyObject>.self))
    XCTAssertEqual(unsafeBitCast(rlmArray.firstObject(), to: SwiftObject.self).floatCol, 1.23)
    XCTAssertEqual(rlmArray.count, 1)

    let set = MutableSet<SwiftObject>()
    set.insert(SwiftObject())
    let rlmSet = ObjectiveCSupport.convert(object: set)
    XCTAssert(rlmSet.isKind(of: RLMSet<AnyObject>.self))
    XCTAssertEqual(unsafeBitCast(rlmSet.allObjects[0], to: SwiftObject.self).floatCol, 1.23)
    XCTAssertEqual(rlmSet.count, 1)

    let map = Map<String, SwiftObject?>()
    map["0"] = SwiftObject()
    let rlmDictionary = ObjectiveCSupport.convert(object: map)
    XCTAssert(rlmDictionary.isKind(of: RLMDictionary<AnyObject, AnyObject>.self))
    XCTAssertEqual(unsafeBitCast(rlmDictionary.allValues[0], to: SwiftObject.self).floatCol, 1.23)
    XCTAssertEqual(rlmDictionary.count, 1)

    let rlmRealm = ObjectiveCSupport.convert(object: realm)
    XCTAssert(rlmRealm.isKind(of: RLMRealm.self))
    XCTAssertEqual(rlmRealm.allObjects("SwiftObject").count, 1)

    let sortDescriptor: RealmSwift.SortDescriptor = "property"
    XCTAssertEqual(sortDescriptor.keyPath,
                   ObjectiveCSupport.convert(object: sortDescriptor).keyPath,
                   "SortDescriptor.keyPath must be equal to RLMSortDescriptor.keyPath")
    XCTAssertEqual(sortDescriptor.ascending,
                   ObjectiveCSupport.convert(object: sortDescriptor).ascending,
                   "SortDescriptor.ascending must be equal to RLMSortDescriptor.ascending")
  }

  func testConfigurationSupport()
  {
    let realm = try! Realm()

    try! realm.write
    {
      realm.add(SwiftObject())
    }

    XCTAssertEqual(realm.configuration.fileURL,
                   ObjectiveCSupport.convert(object: realm.configuration).fileURL,
                   "Configuration.fileURL must be equal to RLMConfiguration.fileURL")

    XCTAssertEqual(realm.configuration.inMemoryIdentifier,
                   ObjectiveCSupport.convert(object: realm.configuration).inMemoryIdentifier,
                   "Configuration.inMemoryIdentifier must be equal to RLMConfiguration.inMemoryIdentifier")

    #if !SWIFT_PACKAGE
      XCTAssertEqual(realm.configuration.syncConfiguration?.partitionValue,
                     ObjectiveCSupport.convert(object: ObjectiveCSupport.convert(object: realm.configuration).syncConfiguration?.partitionValue),
                     "Configuration.syncConfiguration must be equal to RLMConfiguration.syncConfiguration")
    #endif

    XCTAssertEqual(realm.configuration.encryptionKey,
                   ObjectiveCSupport.convert(object: realm.configuration).encryptionKey,
                   "Configuration.encryptionKey must be equal to RLMConfiguration.encryptionKey")

    XCTAssertEqual(realm.configuration.readOnly,
                   ObjectiveCSupport.convert(object: realm.configuration).readOnly,
                   "Configuration.readOnly must be equal to RLMConfiguration.readOnly")

    XCTAssertEqual(realm.configuration.schemaVersion,
                   ObjectiveCSupport.convert(object: realm.configuration).schemaVersion,
                   "Configuration.schemaVersion must be equal to RLMConfiguration.schemaVersion")

    XCTAssertEqual(realm.configuration.deleteRealmIfMigrationNeeded,
                   ObjectiveCSupport.convert(object: realm.configuration).deleteRealmIfMigrationNeeded,
                   "Configuration.deleteRealmIfMigrationNeeded must be equal to RLMConfiguration.deleteRealmIfMigrationNeeded")
  }

  func testAnyRealmValueSupport()
  {
    let obj = SwiftObject()
    let expected: [(RLMValue, AnyRealmValue)] = [
      (NSNumber(1234), .int(1234)),
      (NSNumber(value: true), .bool(true)),
      (NSNumber(value: Float(1234.4567)), .float(1234.4567)),
      (NSNumber(value: Double(1234.4567)), .double(1234.4567)),
      (NSString("hello"), .string("hello")),
      (NSData(data: Data(repeating: 0, count: 64)), .data(Data(repeating: 0, count: 64))),
      (NSDate(timeIntervalSince1970: 1_000_000), .date(Date(timeIntervalSince1970: 1_000_000))),
      (try! RLMObjectId(string: "60425fff91d7a195d5ddac1b"), .objectId(try! ObjectId(string: "60425fff91d7a195d5ddac1b"))),
      (RLMDecimal128(number: 1234.4567), .decimal128(Decimal128(floatLiteral: 1234.4567))),
      (NSUUID(uuidString: "137DECC8-B300-4954-A233-F89909F4FD89")!, .uuid(UUID(uuidString: "137DECC8-B300-4954-A233-F89909F4FD89")!)),
      (obj, .object(obj))
    ]

    func testObjCSupport(_ objCValue: RLMValue, value: AnyRealmValue)
    {
      XCTAssertEqual(ObjectiveCSupport.convert(value: objCValue), value)
    }
    expected.forEach { testObjCSupport($0.0, value: $0.1) }
  }
}
