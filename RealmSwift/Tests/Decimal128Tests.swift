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

class Decimal128Tests: TestCase
{
  // MARK: - Initialization

  func testDecimal128Initialization()
  {
    let d1: Decimal128 = 3.14159
    let d2: Decimal128 = .init(number: 3.14159)
    let d3: Decimal128 = 123
    let d4: Decimal128 = "9.876543"
    let d5 = Decimal128(exactly: 0b0000_0101)

    XCTAssertEqual(d1, 3.14159)
    XCTAssertEqual(d2, 3.14159)
    XCTAssertEqual(d3, 123)
    XCTAssertEqual(d4, "9.876543")
    XCTAssertEqual(d5, 5)
  }

  // MARK: Arithmetic

  func testDecimal128Addition()
  {
    let d1: Decimal128 = 3.144444
    let d2: Decimal128 = 3.144444
    let d3: Decimal128 = "1.234567"
    let d4: Decimal128 = "9.876543"
    let d5 = Decimal128(exactly: 0b0000_0010)
    let d6 = Decimal128(exactly: 0b0000_0001)

    let addition1 = d1 + d2
    let addition2 = d3 + d4
    let addition3 = d5! + d6!

    XCTAssertEqual(addition1, 6.288888)
    XCTAssertEqual(addition2.description, "11.11111")
    XCTAssertEqual(d1, 3.144444)
    XCTAssertEqual(d2, 3.144444)
    XCTAssertEqual(d3.description, "1.234567")
    XCTAssertEqual(d4.description, "9.876543")
    XCTAssertEqual(addition3, 3.0)
    XCTAssertEqual(d5, 2.0)
    XCTAssertEqual(d6, 1.0)
  }

  func testDecimal128Subtraction()
  {
    let d1: Decimal128 = 2.5
    let d2: Decimal128 = 3.5
    let d3: Decimal128 = "2.5"
    let d4: Decimal128 = "3.5"
    let d5 = Decimal128(exactly: 0b0000_0010)
    let d6 = Decimal128(exactly: 0b0000_0001)

    let subtraction1 = d1 - d2
    let subtraction2 = d3 - d4
    let subtraction3 = d5! - d6!

    XCTAssertEqual(subtraction1, -1.0)
    XCTAssertEqual(subtraction2.description, "-1")
    XCTAssertEqual(d1, 2.5)
    XCTAssertEqual(d2, 3.5)
    XCTAssertEqual(d3.description, "2.5")
    XCTAssertEqual(d4.description, "3.5")
    XCTAssertEqual(subtraction3, 1.0)
    XCTAssertEqual(d5, 2.0)
    XCTAssertEqual(d6, 1.0)
  }

  func testDecimal128Division()
  {
    let d1: Decimal128 = 7
    let d2: Decimal128 = 3.5
    let d3: Decimal128 = "0.21"
    let d4: Decimal128 = "0.7"
    let d5 = Decimal128(exactly: 0b0000_0010)
    let d6 = Decimal128(exactly: 0b0000_0001)

    let division1 = d1 / d2
    let division2 = d3 / d4
    let division3 = d5! / d6!

    XCTAssertEqual(division1, 2)
    XCTAssertEqual(division2, 0.3)
    XCTAssertEqual(division3, 2)
  }

  func testDecimal128Multiplication()
  {
    let d1: Decimal128 = 7
    let d2: Decimal128 = 3.5
    let d3: Decimal128 = "0.21"
    let d4: Decimal128 = "0.7"
    let d5 = Decimal128(exactly: 0b0000_0010)

    let multiplication1 = d1 * d2
    let multiplication2 = d3 * d4
    let multiplication3 = d5! * d5!

    XCTAssertEqual(multiplication1, 24.5)
    XCTAssertEqual(multiplication2, 0.147)
    XCTAssertEqual(multiplication3, 4)
  }

  // MARK: Comparison

  func testDecimal128ComparisionEquals()
  {
    let d1: Decimal128 = 3.14159
    let d2: Decimal128 = .init(number: 3.14159)
    let d3: Decimal128 = 123
    let d4: Decimal128 = "123"
    let d5 = Decimal128(exactly: 0b0000_0101)
    let d6: Decimal128 = 5

    XCTAssertTrue(d1 == d2)
    XCTAssertTrue(d3 == d4)
    XCTAssertTrue(d5 == d6)
  }

  func testDecimal128ComparisionNotEquals()
  {
    let d1: Decimal128 = 3.14159
    let d2: Decimal128 = .init(number: 3.14159)
    let d3: Decimal128 = 123
    let d4: Decimal128 = "123"
    let d5 = Decimal128(exactly: 0b0000_0101)
    let d6: Decimal128 = 5

    XCTAssertFalse(d1 != d2)
    XCTAssertFalse(d3 != d4)
    XCTAssertFalse(d5 != d6)
  }

  func testDecimal128ComparisionGreaterThan()
  {
    let d1: Decimal128 = 3.14160
    let d2: Decimal128 = .init(number: 3.14159)
    let d3: Decimal128 = 124
    let d4: Decimal128 = "123"
    let d5 = Decimal128(exactly: 0b0000_0001)
    let d6: Decimal128 = 5

    XCTAssertTrue(d1 > d2)
    XCTAssertTrue(d3 > d4)
    XCTAssertFalse(d5! > d6)
  }

  func testDecimal128ComparisionGreaterThanEquals()
  {
    let d1: Decimal128 = 3.14159
    let d2: Decimal128 = .init(number: 3.14159)
    let d3: Decimal128 = 124
    let d4: Decimal128 = "123"
    let d5 = Decimal128(exactly: 0b0000_0001)
    let d6: Decimal128 = 5

    XCTAssertTrue(d1 >= d2)
    XCTAssertTrue(d3 >= d4)
    XCTAssertFalse(d5! >= d6)
  }

  func testDecimal128ComparisionLessThan()
  {
    let d1: Decimal128 = 3.14159
    let d2: Decimal128 = .init(number: 3.14160)
    let d3: Decimal128 = 122
    let d4: Decimal128 = "123"
    let d5 = Decimal128(exactly: 0b0000_0010)
    let d6: Decimal128 = 1

    XCTAssertTrue(d1 < d2)
    XCTAssertTrue(d3 < d4)
    XCTAssertFalse(d5! < d6)
  }

  func testDecimal128ComparisionLessThanEqual()
  {
    let d1: Decimal128 = 3.14160
    let d2: Decimal128 = .init(number: 3.14160)
    let d3: Decimal128 = 123
    let d4: Decimal128 = "123"
    let d5 = Decimal128(exactly: 0b0000_0010)
    let d6: Decimal128 = 1

    XCTAssertTrue(d1 <= d2)
    XCTAssertTrue(d3 <= d4)
    XCTAssertFalse(d5! <= d6)
  }

  // MARK: Miscellaneous

  func testIsNaN()
  {
    let d1: Decimal128 = .init(value: NSNull())
    XCTAssertTrue(d1.isNaN)
    XCTAssertTrue(d1.isSignaling)
    XCTAssertTrue(d1.isSignalingNaN)
  }

  func testMinMax()
  {
    let min: Decimal128 = .min
    let max: Decimal128 = .max
    XCTAssertGreaterThan(max, min)
    XCTAssertLessThan(min, max)
  }

  func testMagnitude()
  {
    let d1: Decimal128 = -123.321
    let exp1: Decimal128 = 123.321
    let d2: Decimal128 = 456.321
    let exp2: Decimal128 = 456.321
    XCTAssertEqual(d1.magnitude, exp1)
    XCTAssertEqual(d2.magnitude, exp2)
  }

  func testNegate()
  {
    let d1: Decimal128 = -123.321
    let d2: Decimal128 = 456.321
    let exp1: Decimal128 = 123.321
    let exp2: Decimal128 = -456.321
    d1.negate()
    d2.negate()
    XCTAssertEqual(d1, exp1)
    XCTAssertEqual(d2, exp2)
  }

  func testAdvance()
  {
    let d1: Decimal128 = -123.321
    let result1 = d1.advanced(by: -123.321)
    let d2: Decimal128 = -150.0
    let result2 = d2.advanced(by: 300.0)
    XCTAssertEqual(result1, -246.642)
    XCTAssertEqual(result2, 150.0)
  }

  func testDistance()
  {
    let d: Decimal128 = 10.0
    let result1 = d.distance(to: 5.0)
    let result2 = d.distance(to: 15.0)
    XCTAssertEqual(result1, -5.0)
    XCTAssertEqual(result2, 5.0)
  }
}
