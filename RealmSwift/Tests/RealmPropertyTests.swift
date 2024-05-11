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

class RealmPropertyObject: Object
{
  var optionalIntValue = RealmProperty<Int?>()
  var optionalInt8Value = RealmProperty<Int8?>()
  var optionalInt16Value = RealmProperty<Int16?>()
  var optionalInt32Value = RealmProperty<Int32?>()
  var optionalInt64Value = RealmProperty<Int64?>()
  var optionalFloatValue = RealmProperty<Float?>()
  var optionalDoubleValue = RealmProperty<Double?>()
  var optionalBoolValue = RealmProperty<Bool?>()
  /// required for schema validation, but not used in tests.
  @objc dynamic var int = 0
}

class RealmPropertyTests: TestCase
{
  private func test<T: Equatable>(keyPath: KeyPath<RealmPropertyObject, RealmProperty<T?>>,
                                  value: T?)
  {
    let o = RealmPropertyObject()
    o[keyPath: keyPath].value = value
    XCTAssertEqual(o[keyPath: keyPath].value, value)
    o[keyPath: keyPath].value = nil
    XCTAssertNil(o[keyPath: keyPath].value)
    let realm = realmWithTestPath()
    try! realm.write
    {
      realm.add(o)
    }
    XCTAssertNil(o[keyPath: keyPath].value)
    try! realm.write
    {
      o[keyPath: keyPath].value = value
    }
    XCTAssertEqual(o[keyPath: keyPath].value, value)
  }

  func testObject()
  {
    test(keyPath: \.optionalIntValue, value: 123_456)
    test(keyPath: \.optionalInt8Value, value: 127 as Int8)
    test(keyPath: \.optionalInt16Value, value: 32766 as Int16)
    test(keyPath: \.optionalInt32Value, value: 2_147_483_647 as Int32)
    test(keyPath: \.optionalInt64Value, value: 0x7FFF_FFFF_FFFF_FFFF as Int64)
    test(keyPath: \.optionalFloatValue, value: 12345.6789 as Float)
    test(keyPath: \.optionalDoubleValue, value: 12345.6789 as Double)
    test(keyPath: \.optionalBoolValue, value: true)
  }
}
