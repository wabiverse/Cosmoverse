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

import Foundation
import RealmSwift

public class SwiftPerson: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var firstName: String = ""
  @Persisted public var lastName: String = ""
  @Persisted public var age: Int = 30

  public convenience init(firstName: String, lastName: String, age: Int = 30)
  {
    self.init()
    self.firstName = firstName
    self.lastName = lastName
    self.age = age
  }
}

public class SwiftPersonWithAdditionalProperty: SwiftPerson
{
  @Persisted public var newProperty: Int

  override public class func _realmIgnoreClass() -> Bool
  {
    true
  }

  override public class func _realmObjectName() -> String
  {
    "SwiftPerson"
  }

  override public class func className() -> String
  {
    "SwiftPersonWithAdditionalProperty"
  }
}

public class LinkToSwiftPerson: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var person: SwiftPerson?
  @Persisted public var people: List<SwiftPerson>
  @Persisted public var peopleByName: Map<String, SwiftPerson?>
}

@available(macOS 10.15, *)
extension SwiftPerson: ObjectKeyIdentifiable {}

public class SwiftTypesSyncObject: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var boolCol: Bool = true
  @Persisted public var intCol: Int = 1
  @Persisted public var doubleCol: Double = 1.1
  @Persisted public var stringCol: String = "string"
  @Persisted public var binaryCol: Data = "string".data(using: String.Encoding.utf8)!
  @Persisted public var dateCol: Date = .init(timeIntervalSince1970: -1)
  @Persisted public var longCol: Int64 = 1
  @Persisted public var decimalCol: Decimal128 = .init(1)
  @Persisted public var uuidCol: UUID = .init(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
  @Persisted public var objectIdCol: ObjectId
  @Persisted public var objectCol: SwiftPerson?
  @Persisted public var anyCol: AnyRealmValue = .int(1)

  public convenience init(person: SwiftPerson)
  {
    self.init()
    objectCol = person
  }
}

public class SwiftCollectionSyncObject: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var intList: List<Int>
  @Persisted public var boolList: List<Bool>
  @Persisted public var stringList: List<String>
  @Persisted public var dataList: List<Data>
  @Persisted public var dateList: List<Date>
  @Persisted public var doubleList: List<Double>
  @Persisted public var objectIdList: List<ObjectId>
  @Persisted public var decimalList: List<Decimal128>
  @Persisted public var uuidList: List<UUID>
  @Persisted public var anyList: List<AnyRealmValue>
  @Persisted public var objectList: List<SwiftPerson>

  @Persisted public var intSet: MutableSet<Int>
  @Persisted public var stringSet: MutableSet<String>
  @Persisted public var dataSet: MutableSet<Data>
  @Persisted public var dateSet: MutableSet<Date>
  @Persisted public var doubleSet: MutableSet<Double>
  @Persisted public var objectIdSet: MutableSet<ObjectId>
  @Persisted public var decimalSet: MutableSet<Decimal128>
  @Persisted public var uuidSet: MutableSet<UUID>
  @Persisted public var anySet: MutableSet<AnyRealmValue>
  @Persisted public var objectSet: MutableSet<SwiftPerson>

  @Persisted public var otherIntSet: MutableSet<Int>
  @Persisted public var otherStringSet: MutableSet<String>
  @Persisted public var otherDataSet: MutableSet<Data>
  @Persisted public var otherDateSet: MutableSet<Date>
  @Persisted public var otherDoubleSet: MutableSet<Double>
  @Persisted public var otherObjectIdSet: MutableSet<ObjectId>
  @Persisted public var otherDecimalSet: MutableSet<Decimal128>
  @Persisted public var otherUuidSet: MutableSet<UUID>
  @Persisted public var otherAnySet: MutableSet<AnyRealmValue>
  @Persisted public var otherObjectSet: MutableSet<SwiftPerson>

  @Persisted public var intMap: Map<String, Int>
  @Persisted public var stringMap: Map<String, String>
  @Persisted public var dataMap: Map<String, Data>
  @Persisted public var dateMap: Map<String, Date>
  @Persisted public var doubleMap: Map<String, Double>
  @Persisted public var objectIdMap: Map<String, ObjectId>
  @Persisted public var decimalMap: Map<String, Decimal128>
  @Persisted public var uuidMap: Map<String, UUID>
  @Persisted public var anyMap: Map<String, AnyRealmValue>
  @Persisted public var objectMap: Map<String, SwiftPerson?>
}

public class SwiftAnyRealmValueObject: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var anyCol: AnyRealmValue
  @Persisted public var otherAnyCol: AnyRealmValue
}

public class SwiftMissingObject: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var objectCol: SwiftPerson?
  @Persisted public var anyCol: AnyRealmValue
}

public class SwiftUUIDPrimaryKeyObject: Object
{
  @Persisted(primaryKey: true) public var _id: UUID? = UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
  @Persisted public var strCol: String = ""
  @Persisted public var intCol: Int = 0

  public convenience init(id: UUID?, strCol: String, intCol: Int)
  {
    self.init()
    _id = id
    self.strCol = strCol
    self.intCol = intCol
  }
}

public class SwiftStringPrimaryKeyObject: Object
{
  @Persisted(primaryKey: true) public var _id: String? = "1234567890ab1234567890ab"
  @Persisted public var strCol: String = ""
  @Persisted public var intCol: Int = 0

  public convenience init(id: String, strCol: String, intCol: Int)
  {
    self.init()
    _id = id
    self.strCol = strCol
    self.intCol = intCol
  }
}

public class SwiftIntPrimaryKeyObject: Object
{
  @Persisted(primaryKey: true) public var _id: Int = 1_234_567_890
  @Persisted public var strCol: String = ""
  @Persisted public var intCol: Int = 0

  public convenience init(id: Int, strCol: String, intCol: Int)
  {
    self.init()
    _id = id
    self.strCol = strCol
    self.intCol = intCol
  }
}

public class SwiftHugeSyncObject: Object
{
  @Persisted(primaryKey: true) public var _id: ObjectId
  @Persisted public var data: Data?
  @Persisted public var partition: String

  public class func create(key: String = "") -> SwiftHugeSyncObject
  {
    let fakeDataSize = 1_000_000
    return SwiftHugeSyncObject(value: ["data": Data(repeating: 16, count: fakeDataSize),
                                       "partition": key])
  }
}

public let customColumnPropertiesMapping: [String: String] = ["id": "_id",
                                                              "boolCol": "custom_boolCol",
                                                              "intCol": "custom_intCol",
                                                              "doubleCol": "custom_doubleCol",
                                                              "stringCol": "custom_stringCol",
                                                              "binaryCol": "custom_binaryCol",
                                                              "dateCol": "custom_dateCol",
                                                              "longCol": "custom_longCol",
                                                              "decimalCol": "custom_decimalCol",
                                                              "uuidCol": "custom_uuidCol",
                                                              "objectIdCol": "custom_objectIdCol",
                                                              "objectCol": "custom_objectCol"]

public class SwiftCustomColumnObject: Object
{
  @Persisted(primaryKey: true) public var id: ObjectId
  @Persisted public var boolCol: Bool = true
  @Persisted public var intCol: Int = 1
  @Persisted public var doubleCol: Double = 1.1
  @Persisted public var stringCol: String = "string"
  @Persisted public var binaryCol = "string".data(using: String.Encoding.utf8)!
  @Persisted public var dateCol: Date = .init(timeIntervalSince1970: -1)
  @Persisted public var longCol: Int64 = 1
  @Persisted public var decimalCol: Decimal128 = .init(1)
  @Persisted public var uuidCol: UUID = .init(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
  @Persisted public var objectIdCol: ObjectId?
  @Persisted public var objectCol: SwiftCustomColumnObject?

  override public class func propertiesMapping() -> [String: String]
  {
    customColumnPropertiesMapping
  }
}
