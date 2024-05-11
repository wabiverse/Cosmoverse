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
import XCTest

#if canImport(RealmTestSupport)
  import RealmTestSupport
#endif

let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"

class SwiftRLMUnicodeTests: RLMTestCase
{
  // Swift models

  func testUTF8StringContents()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = SwiftRLMStringObject.create(in: realm, withValue: [utf8TestString])
    try! realm.commitWriteTransaction()

    let obj1 = SwiftRLMStringObject.allObjects(in: realm).firstObject() as! SwiftRLMStringObject
    XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

    let obj2 = SwiftRLMStringObject.objects(in: realm, where: "stringCol == %@", utf8TestString).firstObject() as! SwiftRLMStringObject
    XCTAssertTrue(obj1.isEqual(to: obj2), "Querying a realm searching for a string with UTF8 content should work")
  }

  func testUTF8PropertyWithUTF8StringContents()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = SwiftRLMUTF8Object.create(in: realm, withValue: [utf8TestString])
    try! realm.commitWriteTransaction()

    let obj1 = SwiftRLMUTF8Object.allObjects(in: realm).firstObject() as! SwiftRLMUTF8Object
    XCTAssertEqual(obj1.柱колоéнǢкƱаم👍, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

    // Test fails because of rdar://17735684
//        let obj2 = SwiftRLMUTF8Object.objectsInRealm(realm, "柱колоéнǢкƱаم👍 == %@", utf8TestString).firstObject() as SwiftRLMUTF8Object
//        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
  }

  // Objective-C models

  func testUTF8StringContents_objc()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = StringObject.create(in: realm, withValue: [utf8TestString])
    try! realm.commitWriteTransaction()

    let obj1 = StringObject.allObjects(in: realm).firstObject() as! StringObject
    XCTAssertEqual(obj1.stringCol, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

    // Temporarily commented out because variadic import seems broken
    let obj2 = StringObject.objects(in: realm, where: "stringCol == %@", utf8TestString).firstObject() as! StringObject
    XCTAssertTrue(obj1.isEqual(to: obj2), "Querying a realm searching for a string with UTF8 content should work")
  }

  func testUTF8PropertyWithUTF8StringContents_objc()
  {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    _ = UTF8Object.create(in: realm, withValue: [utf8TestString])
    try! realm.commitWriteTransaction()

    let obj1 = UTF8Object.allObjects(in: realm).firstObject() as! UTF8Object
    XCTAssertEqual(obj1.柱колоéнǢкƱаم, utf8TestString, "Storing and retrieving a string with UTF8 content should work")

    // Test fails because of rdar://17735684
//        let obj2 = UTF8Object.objectsInRealm(realm, "柱колоéнǢкƱаم == %@", utf8TestString).firstObject() as UTF8Object
//        XCTAssertEqual(obj1, obj2, "Querying a realm searching for a string with UTF8 content should work")
  }
}
