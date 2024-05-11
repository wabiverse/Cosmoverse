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
@_spi(RealmSwiftPrivate) import RealmSwift

final class ObjectCustomPropertiesTests: TestCase
{
  override func tearDown()
  {
    super.tearDown()
    CustomPropertiesObject.injected_customRealmProperties = nil
  }

  func testCustomProperties() throws
  {
    CustomPropertiesObject.injected_customRealmProperties = [CustomPropertiesObject.preMadeRLMProperty]

    let customProperties = try XCTUnwrap(CustomPropertiesObject._customRealmProperties())
    XCTAssertEqual(customProperties.count, 1)
    XCTAssert(customProperties.first === CustomPropertiesObject.preMadeRLMProperty)

    // Assert properties are custom properties
    let properties = CustomPropertiesObject._getProperties()
    XCTAssertEqual(properties.count, 1)
    XCTAssert(properties.first === CustomPropertiesObject.preMadeRLMProperty)
  }

  func testNoCustomProperties()
  {
    CustomPropertiesObject.injected_customRealmProperties = nil

    let customProperties = CustomPropertiesObject._customRealmProperties()
    XCTAssertNil(customProperties)

    // Assert properties are generated despite `nil` custom properties
    let properties = CustomPropertiesObject._getProperties()
    XCTAssertEqual(properties.count, 1)
    XCTAssert(properties.first !== CustomPropertiesObject.preMadeRLMProperty)
  }

  func testEmptyCustomProperties() throws
  {
    CustomPropertiesObject.injected_customRealmProperties = []

    let customProperties = try XCTUnwrap(CustomPropertiesObject._customRealmProperties())
    XCTAssertEqual(customProperties.count, 0)

    // Assert properties are custom properties (rather incorrectly)
    let properties = CustomPropertiesObject._getProperties()
    XCTAssertEqual(properties.count, 0)
  }
}

@objc(CustomPropertiesObject)
private final class CustomPropertiesObject: Object
{
  @Persisted var value: String

  override static func _customRealmProperties() -> [RLMProperty]?
  {
    injected_customRealmProperties
  }

  static var injected_customRealmProperties: [RLMProperty]?
  static let preMadeRLMProperty = RLMProperty(name: "value", objectType: CustomPropertiesObject.self, valueType: String.self)
}
