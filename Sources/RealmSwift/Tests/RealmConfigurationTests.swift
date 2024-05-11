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

import class Realm.Private.RLMRealmConfiguration
import RealmSwift
import XCTest

class RealmConfigurationTests: TestCase
{
  func testDefaultConfiguration()
  {
    let defaultConfiguration = Realm.Configuration.defaultConfiguration

    XCTAssertEqual(defaultConfiguration.fileURL, try! Realm().configuration.fileURL)
    XCTAssertNil(defaultConfiguration.inMemoryIdentifier)
    XCTAssertNil(defaultConfiguration.encryptionKey)
    XCTAssertFalse(defaultConfiguration.readOnly)
    XCTAssertEqual(defaultConfiguration.schemaVersion, 0)
    XCTAssert(defaultConfiguration.migrationBlock == nil)
  }

  func testSetDefaultConfiguration()
  {
    let fileURL = Realm.Configuration.defaultConfiguration.fileURL
    let configuration = Realm.Configuration(fileURL: URL(fileURLWithPath: "/dev/null"))
    Realm.Configuration.defaultConfiguration = configuration
    XCTAssertEqual(Realm.Configuration.defaultConfiguration.fileURL, URL(fileURLWithPath: "/dev/null"))
    Realm.Configuration.defaultConfiguration.fileURL = fileURL
  }

  func testCannotSetMutuallyExclusiveProperties()
  {
    var configuration = Realm.Configuration()
    configuration.readOnly = true
    configuration.deleteRealmIfMigrationNeeded = true
    assertThrows(try! Realm(configuration: configuration),
                 reason: "Cannot set `deleteRealmIfMigrationNeeded` when `readOnly` is set.")
  }
}
