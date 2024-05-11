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

#if canImport(RealmTestSupport)
  import RealmSwiftSyncTestSupport
#endif

@available(macOS 13, *)
@objc(SwiftObjectServerPartitionTests)
class SwiftObjectServerPartitionTests: SwiftSyncTestCase
{
  func configuration(_ user: User, _ partitionValue: some BSON) -> Realm.Configuration
  {
    var config = user.configuration(partitionValue: partitionValue)
    config.objectTypes = [SwiftPerson.self]
    return config
  }

  func writeObjects(_ user: User, _ partitionValue: some BSON) throws
  {
    try autoreleasepool
    {
      let realm = try Realm(configuration: configuration(user, partitionValue))
      try realm.write
      {
        realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
        realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
        realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
        realm.add(SwiftPerson(firstName: "George", lastName: "Harrison"))
      }
      waitForUploads(for: realm)
    }
  }

  func roundTripForPartitionValue(partitionValue: some BSON) throws
  {
    let partitionType = partitionBsonType(ObjectiveCSupport.convert(object: AnyBSON(partitionValue))!)
    let appId = try RealmServer.shared.createApp(partitionKeyType: partitionType, types: [SwiftPerson.self])
    let partitionApp = app(id: appId)
    let user = createUser(for: partitionApp)
    let user2 = createUser(for: partitionApp)
    let realm = try Realm(configuration: configuration(user, partitionValue))
    checkCount(expected: 0, realm, SwiftPerson.self)

    try writeObjects(user2, partitionValue)
    waitForDownloads(for: realm)
    checkCount(expected: 4, realm, SwiftPerson.self)
    XCTAssertEqual(realm.objects(SwiftPerson.self).filter { $0.firstName == "Ringo" }.count, 1)

    try writeObjects(user2, partitionValue)
    waitForDownloads(for: realm)
    checkCount(expected: 8, realm, SwiftPerson.self)
    XCTAssertEqual(realm.objects(SwiftPerson.self).filter { $0.firstName == "Ringo" }.count, 2)
  }

  func testSwiftRoundTripForObjectIdPartitionValue() throws
  {
    try roundTripForPartitionValue(partitionValue: ObjectId("1234567890ab1234567890ab"))
  }

  func testSwiftRoundTripForUUIDPartitionValue() throws
  {
    try roundTripForPartitionValue(partitionValue: UUID(uuidString: "b1c11e54-e719-4275-b631-69ec3f2d616d")!)
  }

  func testSwiftRoundTripForStringPartitionValue() throws
  {
    try roundTripForPartitionValue(partitionValue: "1234567890ab1234567890ab")
  }

  func testSwiftRoundTripForIntPartitionValue() throws
  {
    try roundTripForPartitionValue(partitionValue: 1_234_567_890)
  }
}
