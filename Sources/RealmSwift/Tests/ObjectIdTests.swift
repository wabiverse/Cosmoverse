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

class ObjectIdTests: TestCase
{
  func testObjectIdInitialization()
  {
    let strValue = "000123450000ffbeef91906c"
    let objectId = try! ObjectId(string: strValue)
    XCTAssertEqual(objectId.stringValue, strValue)
    XCTAssertEqual(strValue, objectId.stringValue)

    let now = Date()
    let objectId2 = ObjectId(timestamp: now, machineId: 10, processId: 20)
    XCTAssertEqual(Int(now.timeIntervalSince1970), Int(objectId2.timestamp.timeIntervalSince1970))
  }

  func testObjectIdComparision()
  {
    let strValue = "000123450000ffbeef91906c"
    let objectId = try! ObjectId(string: strValue)

    let strValue2 = "000123450000ffbeef91906d"
    let objectId2 = try! ObjectId(string: strValue2)

    let strValue3 = "000123450000ffbeef91906c"
    let objectId3 = try! ObjectId(string: strValue3)

    XCTAssertTrue(objectId != objectId2)
    XCTAssertTrue(objectId == objectId3)
  }

  func testObjectIdGreaterThan()
  {
    let strValue = "000123450000ffbeef91906c"
    let objectId = try! ObjectId(string: strValue)

    let strValue2 = "000123450000ffbeef91906d"
    let objectId2 = try! ObjectId(string: strValue2)

    let strValue3 = "000123450000ffbeef91906c"
    let objectId3 = try! ObjectId(string: strValue3)

    XCTAssertTrue(objectId2 > objectId)
    XCTAssertFalse(objectId > objectId3)
  }

  func testObjectIdGreaterThanOrEqualTo()
  {
    let strValue = "000123450000ffbeef91906c"
    let objectId = try! ObjectId(string: strValue)

    let strValue2 = "000123450000ffbeef91906d"
    let objectId2 = try! ObjectId(string: strValue2)

    let strValue3 = "000123450000ffbeef91906c"
    let objectId3 = try! ObjectId(string: strValue3)

    XCTAssertTrue(objectId2 >= objectId)
    XCTAssertTrue(objectId >= objectId3)
  }

  func testObjectIdLessThan()
  {
    let strValue = "000123450000ffbeef91906c"
    let objectId = try! ObjectId(string: strValue)

    let strValue2 = "000123450000ffbeef91906d"
    let objectId2 = try! ObjectId(string: strValue2)

    let strValue3 = "000123450000ffbeef91906c"
    let objectId3 = try! ObjectId(string: strValue3)

    XCTAssertTrue(objectId < objectId2)
    XCTAssertFalse(objectId < objectId3)
  }

  func testObjectIdLessThanOrEqualTo()
  {
    let strValue = "000123450000ffbeef91906c"
    let objectId = try! ObjectId(string: strValue)

    let strValue2 = "000123450000ffbeef91906d"
    let objectId2 = try! ObjectId(string: strValue2)

    let strValue3 = "000123450000ffbeef91906c"
    let objectId3 = try! ObjectId(string: strValue3)

    XCTAssertTrue(objectId <= objectId2)
    XCTAssertTrue(objectId <= objectId3)
  }
}
