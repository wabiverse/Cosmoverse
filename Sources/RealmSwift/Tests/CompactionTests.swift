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

// MARK: Expected Sizes

private var expectedTotalBytesBefore = 0
private let expectedUsedBytesBeforeMin = 50000
private var count = 1000

// MARK: Helpers

private func fileSize(path: String) -> Int
{
  let attributes = try! FileManager.default.attributesOfItem(atPath: path)
  return attributes[.size] as! Int
}

// MARK: Tests

class CompactionTests: TestCase
{
  override func setUp()
  {
    super.setUp()
    autoreleasepool
    {
      // Make compactable Realm
      let realm = realmWithTestPath()
      let uuid = UUID().uuidString
      try! realm.write
      {
        realm.create(SwiftStringObject.self, value: ["A"])
        for _ in 0 ..< count
        {
          realm.create(SwiftStringObject.self, value: [uuid])
        }
        realm.create(SwiftStringObject.self, value: ["B"])
      }
    }
    expectedTotalBytesBefore = fileSize(path: testRealmURL().path)
  }

  func testSuccessfulCompactOnLaunch()
  {
    // Configure the Realm to compact on launch
    let config = Realm.Configuration(fileURL: testRealmURL(),
                                     shouldCompactOnLaunch: { totalBytes, usedBytes in
                                       // Confirm expected sizes
                                       XCTAssertEqual(totalBytes, expectedTotalBytesBefore)
                                       XCTAssert((usedBytes < totalBytes) && (usedBytes > expectedUsedBytesBeforeMin))
                                       return true
                                     })

    // Confirm expected sizes before and after opening the Realm
    XCTAssertEqual(fileSize(path: config.fileURL!.path), expectedTotalBytesBefore)
    let realm = try! Realm(configuration: config)
    XCTAssertLessThan(fileSize(path: config.fileURL!.path), expectedTotalBytesBefore)

    // Validate that the file still contains what it should
    XCTAssertEqual(realm.objects(SwiftStringObject.self).count, count + 2)
    XCTAssertEqual("A", realm.objects(SwiftStringObject.self).first?.stringCol)
    XCTAssertEqual("B", realm.objects(SwiftStringObject.self).last?.stringCol)
  }
}
