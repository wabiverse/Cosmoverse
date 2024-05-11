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

class SchemaTests: TestCase
{
  var schema: Schema!

  override func setUp()
  {
    super.setUp()
    autoreleasepool
    {
      self.schema = try! Realm().schema
    }
  }

  func testObjectSchema()
  {
    let objectSchema = schema.objectSchema
    XCTAssertTrue(!objectSchema.isEmpty)
  }

  func testDescription()
  {
    XCTAssert(schema.description as Any is String)
  }

  func testSubscript()
  {
    XCTAssertEqual(schema["SwiftObject"]!.className, "SwiftObject")
    XCTAssertNil(schema["NoSuchClass"])
  }

  func testEquals()
  {
    XCTAssertTrue(try! schema == Realm().schema)
  }

  func testNoSchemaForUnpersistedObjectClasses()
  {
    XCTAssertNil(schema["RLMObject"])
    XCTAssertNil(schema["RLMObjectBase"])
    XCTAssertNil(schema["RLMDynamicObject"])
    XCTAssertNil(schema["Object"])
    XCTAssertNil(schema["DynamicObject"])
    XCTAssertNil(schema["MigrationObject"])
  }

  func testValidNestedClass() throws
  {
    let privateSubclass = try XCTUnwrap(schema["PrivateObjectSubclass"])
    XCTAssertEqual(privateSubclass.className, "PrivateObjectSubclass")

    let parent = try XCTUnwrap(schema["ObjectWithNestedEmbeddedObject"])
    XCTAssertEqual(parent.properties[1].objectClassName, "ObjectWithNestedEmbeddedObject_NestedInnerClass")
    XCTAssertNotNil(schema["ObjectWithNestedEmbeddedObject_NestedInnerClass"])
  }
}
