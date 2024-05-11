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

class ObjectSchemaTests: TestCase
{
  var objectSchema: ObjectSchema!

  var swiftObjectSchema: ObjectSchema
  {
    try! Realm().schema["SwiftObject"]!
  }

  func testProperties()
  {
    let objectSchema = swiftObjectSchema
    let propertyNames = objectSchema.properties.map(\.name)
    XCTAssertEqual(propertyNames,
                   ["boolCol", "intCol", "int8Col", "int16Col", "int32Col", "int64Col", "intEnumCol", "floatCol", "doubleCol",
                    "stringCol", "binaryCol", "dateCol", "decimalCol",
                    "objectIdCol", "objectCol", "uuidCol", "anyCol", "arrayCol", "setCol", "mapCol"])
  }

  /// Cannot name testClassName() because it interferes with the method on XCTest
  func testClassNameProperty()
  {
    let objectSchema = swiftObjectSchema
    XCTAssertEqual(objectSchema.className, "SwiftObject")
  }

  func testObjectClass()
  {
    let objectSchema = swiftObjectSchema
    XCTAssertTrue(objectSchema.objectClass === SwiftObject.self)
  }

  func testPrimaryKeyProperty()
  {
    let objectSchema = swiftObjectSchema
    XCTAssertNil(objectSchema.primaryKeyProperty)
    XCTAssertEqual(try! Realm().schema["SwiftPrimaryStringObject"]!.primaryKeyProperty!.name, "stringCol")
  }

  func testDescription()
  {
    let objectSchema = swiftObjectSchema
    let expected = """
      SwiftObject {
          boolCol {
              type = bool;
              columnName = boolCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          intCol {
              type = int;
              columnName = intCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          int8Col {
              type = int;
              columnName = int8Col;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          int16Col {
              type = int;
              columnName = int16Col;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          int32Col {
              type = int;
              columnName = int32Col;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          int64Col {
              type = int;
              columnName = int64Col;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          intEnumCol {
              type = int;
              columnName = intEnumCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          floatCol {
              type = float;
              columnName = floatCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          doubleCol {
              type = double;
              columnName = doubleCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          stringCol {
              type = string;
              columnName = stringCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          binaryCol {
              type = data;
              columnName = binaryCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          dateCol {
              type = date;
              columnName = dateCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          decimalCol {
              type = decimal128;
              columnName = decimalCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          objectIdCol {
              type = object id;
              columnName = objectIdCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          objectCol {
              type = object;
              objectClassName = SwiftBoolObject;
              linkOriginPropertyName = (null);
              columnName = objectCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = YES;
          }
          uuidCol {
              type = uuid;
              columnName = uuidCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          anyCol {
              type = mixed;
              columnName = anyCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          arrayCol {
              type = object;
              objectClassName = SwiftBoolObject;
              linkOriginPropertyName = (null);
              columnName = arrayCol;
              indexed = NO;
              isPrimary = NO;
              array = YES;
              set = NO;
              dictionary = NO;
              optional = NO;
          }
          setCol {
              type = object;
              objectClassName = SwiftBoolObject;
              linkOriginPropertyName = (null);
              columnName = setCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = YES;
              dictionary = NO;
              optional = NO;
          }
          mapCol {
              type = object;
              objectClassName = SwiftBoolObject;
              linkOriginPropertyName = (null);
              columnName = mapCol;
              indexed = NO;
              isPrimary = NO;
              array = NO;
              set = NO;
              dictionary = YES;
              optional = YES;
          }
      }
      """
    XCTAssertEqual(objectSchema.description, expected.replacingOccurrences(of: "    ", with: "\t"))
  }

  func testSubscript()
  {
    let objectSchema = swiftObjectSchema
    XCTAssertNil(objectSchema["noSuchProperty"])
    XCTAssertEqual(objectSchema["boolCol"]!.name, "boolCol")
  }

  func testEquals()
  {
    let objectSchema = swiftObjectSchema
    XCTAssert(try! objectSchema == Realm().schema["SwiftObject"]!)
    XCTAssert(try! objectSchema != Realm().schema["SwiftStringObject"]!)
  }
}
