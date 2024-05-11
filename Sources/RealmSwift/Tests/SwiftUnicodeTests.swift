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

let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"

class SwiftUnicodeTests: TestCase
{
  func testUTF8StringContents()
  {
    let realm = realmWithTestPath()

    try! realm.write
    {
      realm.create(SwiftStringObject.self, value: [utf8TestString])
    }

    let obj1 = realm.objects(SwiftStringObject.self).first!
    XCTAssertEqual(obj1.stringCol, utf8TestString)

    let obj2 = realm.objects(SwiftStringObject.self).filter("stringCol == %@", utf8TestString).first!
    assertEqual(obj1, obj2)
    XCTAssertEqual(obj2.stringCol, utf8TestString)

    XCTAssertEqual(Int(0), realm.objects(SwiftStringObject.self).filter("stringCol != %@", utf8TestString).count)
  }

  func testUTF8PropertyWithUTF8StringContents()
  {
    let realm = realmWithTestPath()
    try! realm.write
    {
      realm.create(SwiftUTF8Object.self, value: [utf8TestString])
    }

    let obj1 = realm.objects(SwiftUTF8Object.self).first!
    XCTAssertEqual(obj1.柱колоéнǢкƱаم👍, utf8TestString,
                   "Storing and retrieving a string with UTF8 content should work")

    let obj2 = realm.objects(SwiftUTF8Object.self).filter("%K == %@", "柱колоéнǢкƱаم👍", utf8TestString).first!
    assertEqual(obj1, obj2)
  }
}
