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

class SortDescriptorTests: TestCase
{
  let sortDescriptor = SortDescriptor(keyPath: "property")

  func testAscendingDefaultsToTrue()
  {
    XCTAssertTrue(sortDescriptor.ascending)
  }

  func testReversedReturnsReversedDescriptor()
  {
    let reversed = sortDescriptor.reversed()
    XCTAssertEqual(reversed.keyPath, sortDescriptor.keyPath, "Key path should stay the same when reversed.")
    XCTAssertFalse(reversed.ascending)
    XCTAssertTrue(reversed.reversed().ascending)
  }

  func testDescription()
  {
    XCTAssertEqual(sortDescriptor.description, "SortDescriptor(keyPath: property, direction: ascending)")
  }

  func testStringLiteralConvertible()
  {
    let literalSortDescriptor: RealmSwift.SortDescriptor = "property"
    XCTAssertEqual(sortDescriptor, literalSortDescriptor,
                   "SortDescriptor should conform to StringLiteralConvertible")
  }

  func testComparison()
  {
    let sortDescriptor1 = SortDescriptor(keyPath: "property1", ascending: true)
    let sortDescriptor2 = SortDescriptor(keyPath: "property1", ascending: false)
    let sortDescriptor3 = SortDescriptor(keyPath: "property2", ascending: true)
    let sortDescriptor4 = SortDescriptor(keyPath: "property2", ascending: false)

    // validate different
    XCTAssertNotEqual(sortDescriptor1, sortDescriptor2, "Should not match")
    XCTAssertNotEqual(sortDescriptor1, sortDescriptor3, "Should not match")
    XCTAssertNotEqual(sortDescriptor1, sortDescriptor4, "Should not match")

    XCTAssertNotEqual(sortDescriptor2, sortDescriptor3, "Should not match")
    XCTAssertNotEqual(sortDescriptor2, sortDescriptor4, "Should not match")

    XCTAssertNotEqual(sortDescriptor3, sortDescriptor4, "Should not match")

    let sortDescriptor5 = SortDescriptor(keyPath: "property1", ascending: true)
    let sortDescriptor6 = SortDescriptor(keyPath: "property2", ascending: true)

    // validate same
    XCTAssertEqual(sortDescriptor1, sortDescriptor5, "Should match")
    XCTAssertEqual(sortDescriptor3, sortDescriptor6, "Should match")
  }
}
