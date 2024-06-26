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

/// A tag protocol which marks types that can be used as the partition value
/// for synchronized Realms.
public protocol PartitionValue: Sendable
{}

/// Protocol representing a BSON value.
/// - SeeAlso: bsonspec.org
public protocol BSON: PartitionValue, Equatable
{}

extension NSNull: BSON
{}

extension Int: BSON
{}

extension Int32: BSON
{}

extension Int64: BSON
{}

extension Bool: BSON
{}

extension Double: BSON
{}

extension String: BSON
{}

extension Data: BSON
{}

extension Date: BSON
{}

extension Decimal128: BSON
{}

extension ObjectId: BSON
{}

extension UUID: BSON
{}

/// A Dictionary object representing a `BSON` document.
public typealias Document = [String: AnyBSON?]

extension [String: AnyBSON?]: BSON, PartitionValue {}

extension [AnyBSON?]: BSON, PartitionValue {}

extension NSRegularExpression: BSON
{}

/// MaxKey will always be the greatest value when comparing to other BSON types
public typealias MaxKey = RLMMaxKey

extension MaxKey: BSON
{}

/// MinKey will always be the smallest value when comparing to other BSON types
public typealias MinKey = RLMMinKey

extension MinKey: BSON
{}

/// Enum representing a BSON value.
/// - SeeAlso: bsonspec.org
@frozen public enum AnyBSON: BSON, Sendable
{
  /// A BSON double.
  case double(Double)

  /// A BSON string.
  /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#string
  case string(String)

  /// A BSON document.
  indirect case document(Document)

  /// A BSON array.
  indirect case array([AnyBSON?])

  /// A BSON binary.
  case binary(Data)

  /// A BSON ObjectId.
  /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#objectid
  case objectId(ObjectId)

  /// A BSON boolean.
  case bool(Bool)

  /// A BSON UTC datetime.
  /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#date
  case datetime(Date)

  /// A BSON regular expression.
  case regex(NSRegularExpression)

  /// A BSON int32.
  case int32(Int32)

  /// A BSON timestamp.
  /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#timestamps
  case timestamp(Date)

  /// A BSON int64.
  case int64(Int64)

  /// A BSON Decimal128.
  /// - SeeAlso: https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst
  case decimal128(Decimal128)

  /// A UUID.
  case uuid(UUID)

  /// A BSON minKey.
  case minKey

  /// A BSON maxKey.
  case maxKey

  /// A BSON null type.
  case null

  /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
  /// this will result in an `.int32`.
  public init(_ int: Int)
  {
    if MemoryLayout<Int>.size == 4
    {
      self = .int32(Int32(int))
    }
    else
    {
      self = .int64(Int64(int))
    }
  }

  /// :nodoc:
  static func convert(_ bson: some Any) -> AnyBSON
  {
    switch bson
    {
      case let val as Int:
        .int64(Int64(val))
      case let val as Int32:
        .int32(val)
      case let val as Int64:
        .int64(val)
      case let val as Double:
        .double(val)
      case let val as String:
        .string(val)
      case let val as Data:
        .binary(val)
      case let val as Date:
        .datetime(val)
      case let val as Decimal128:
        .decimal128(val)
      case let val as UUID:
        .uuid(val)
      case let val as ObjectId:
        .objectId(val)
      case let val as Document:
        .document(val)
      case let val as [AnyBSON?]:
        .array(val)
      case let val as Bool:
        .bool(val)
      case is MaxKey:
        .maxKey
      case is MinKey:
        .minKey
      case let val as NSRegularExpression:
        .regex(val)
      case let val as AnyBSON:
        val
      default:
        .null
    }
  }

  /// Initialize a `BSON` from a type `T`. If this is not a valid `BSON` type,
  /// it will be considered `BSON` null type and will return `nil`.
  public init(_ bson: some BSON)
  {
    self = Self.convert(bson)
  }

  /// Initialize a `BSON` from type `PartitionValue`. If this is not a valid `BSON` type,
  /// it will be considered `BSON` null type and will return `nil`.
  init(partitionValue: PartitionValue)
  {
    self = Self.convert(partitionValue)
  }

  /// If this `BSON` is an `.int32`, return it as an `Int32`. Otherwise, return nil.
  public var int32Value: Int32?
  {
    guard case let .int32(i) = self
    else
    {
      return nil
    }
    return i
  }

  /// If this `BSON` is a `.regex`, return it as a `RegularExpression`. Otherwise, return nil.
  public var regexValue: NSRegularExpression?
  {
    guard case let .regex(r) = self
    else
    {
      return nil
    }
    return r
  }

  /// If this `BSON` is an `.int64`, return it as an `Int64`. Otherwise, return nil.
  public var int64Value: Int64?
  {
    guard case let .int64(i) = self
    else
    {
      return nil
    }
    return i
  }

  /// If this `BSON` is an `.objectId`, return it as an `ObjectId`. Otherwise, return nil.
  public var objectIdValue: ObjectId?
  {
    guard case let .objectId(o) = self
    else
    {
      return nil
    }
    return o
  }

  /// If this `BSON` is a `.date`, return it as a `Date`. Otherwise, return nil.
  public var dateValue: Date?
  {
    guard case let .datetime(d) = self
    else
    {
      return nil
    }
    return d
  }

  /// If this `BSON` is an `.array`, return it as an `[BSON]`. Otherwise, return nil.
  public var arrayValue: [AnyBSON?]?
  {
    guard case let .array(a) = self
    else
    {
      return nil
    }
    return a
  }

  /// If this `BSON` is a `.string`, return it as a `String`. Otherwise, return nil.
  public var stringValue: String?
  {
    guard case let .string(s) = self
    else
    {
      return nil
    }
    return s
  }

  /// If this `BSON` is a `.document`, return it as a `Document`. Otherwise, return nil.
  public var documentValue: Document?
  {
    guard case let .document(d) = self
    else
    {
      return nil
    }
    return d
  }

  /// If this `BSON` is a `.bool`, return it as an `Bool`. Otherwise, return nil.
  public var boolValue: Bool?
  {
    guard case let .bool(b) = self
    else
    {
      return nil
    }
    return b
  }

  /// If this `BSON` is a `.binary`, return it as a `Binary`. Otherwise, return nil.
  public var binaryValue: Data?
  {
    guard case let .binary(b) = self
    else
    {
      return nil
    }
    return b
  }

  /// If this `BSON` is a `.double`, return it as a `Double`. Otherwise, return nil.
  public var doubleValue: Double?
  {
    guard case let .double(d) = self
    else
    {
      return nil
    }
    return d
  }

  /// If this `BSON` is a `.decimal128`, return it as a `Decimal128`. Otherwise, return nil.
  public var decimal128Value: Decimal128?
  {
    guard case let .decimal128(d) = self
    else
    {
      return nil
    }
    return d
  }

  /// If this `BSON` is a `.timestamp`, return it as a `Timestamp`. Otherwise, return nil.
  public var timestampValue: Date?
  {
    guard case let .timestamp(t) = self
    else
    {
      return nil
    }
    return t
  }

  /// If this `BSON` is a `.uuid`, return it as a `UUID`. Otherwise, return nil.
  public var uuidValue: UUID?
  {
    guard case let .uuid(s) = self
    else
    {
      return nil
    }
    return s
  }

  /// If this `BSON` is a `.null` return true. Otherwise, false.
  public var isNull: Bool
  {
    self == .null
  }

  /// Return this BSON as an `Int` if possible.
  /// This will coerce non-integer numeric cases (e.g. `.double`) into an `Int` if such coercion would be lossless.
  public func asInt() -> Int?
  {
    switch self
    {
      case let .int32(value):
        Int(value)
      case let .int64(value):
        Int(exactly: value)
      case let .double(value):
        Int(exactly: value)
      default:
        nil
    }
  }

  /// Return this BSON as an `Int32` if possible.
  /// This will coerce numeric cases (e.g. `.double`) into an `Int32` if such coercion would be lossless.
  public func asInt32() -> Int32?
  {
    switch self
    {
      case let .int32(value):
        value
      case let .int64(value):
        Int32(exactly: value)
      case let .double(value):
        Int32(exactly: value)
      default:
        nil
    }
  }

  /// Return this BSON as an `Int64` if possible.
  /// This will coerce numeric cases (e.g. `.double`) into an `Int64` if such coercion would be lossless.
  public func asInt64() -> Int64?
  {
    switch self
    {
      case let .int32(value):
        Int64(value)
      case let .int64(value):
        value
      case let .double(value):
        Int64(exactly: value)
      default:
        nil
    }
  }

  /// Return this BSON as a `Double` if possible.
  /// This will coerce numeric cases (e.g. `.decimal128`) into a `Double` if such coercion would be lossless.
  public func asDouble() -> Double?
  {
    switch self
    {
      case let .double(d):
        return d
      default:
        guard let intValue = asInt()
        else
        {
          return nil
        }
        return Double(intValue)
    }
  }

  /// Return this BSON as a `Decimal128` if possible.
  /// This will coerce numeric cases (e.g. `.double`) into a `Decimal128` if such coercion would be lossless.
  public func asDecimal128() -> Decimal128?
  {
    let str: String
    switch self
    {
      case let .decimal128(d):
        return d
      case let .int64(i):
        str = String(i)
      case let .int32(i):
        str = String(i)
      case let .double(d):
        str = String(d)
      default:
        return nil
    }
    return try? Decimal128(string: str)
  }

  /// Return this BSON as a `T` if possible, otherwise nil.
  public func value<T: BSON>() -> T?
  {
    switch self
    {
      case let .int32(val):
        if T.self == Int.self, MemoryLayout<Int>.size == 4
        {
          return Int(val) as? T
        }
        return val as? T
      case let .int64(val):
        if T.self == Int.self, MemoryLayout<Int>.size != 4
        {
          return Int(val) as? T
        }
        return val as? T
      case let .bool(val):
        return val as? T
      case let .double(val):
        return val as? T
      case let .string(val):
        return val as? T
      case let .binary(val):
        return val as? T
      case let .datetime(val):
        return val as? T
      case let .decimal128(val):
        return val as? T
      case let .objectId(val):
        return val as? T
      case let .document(val):
        return val as? T
      case let .array(val):
        return val as? T
      case .maxKey:
        return MaxKey() as? T
      case .minKey:
        return MinKey() as? T
      case let .regex(val):
        return val as? T
      default:
        return nil
    }
  }
}

extension AnyBSON: ExpressibleByStringLiteral
{
  public init(stringLiteral value: String)
  {
    self = .string(value)
  }
}

extension AnyBSON: ExpressibleByBooleanLiteral
{
  public init(booleanLiteral value: Bool)
  {
    self = .bool(value)
  }
}

extension AnyBSON: ExpressibleByFloatLiteral
{
  public init(floatLiteral value: Double)
  {
    self = .double(value)
  }
}

extension AnyBSON: ExpressibleByIntegerLiteral
{
  /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
  /// this will result in an `.int32`.
  public init(integerLiteral value: Int)
  {
    self.init(value)
  }
}

extension AnyBSON: ExpressibleByDictionaryLiteral
{
  public init(dictionaryLiteral elements: (String, AnyBSON?)...)
  {
    self = .document(Document(uniqueKeysWithValues: elements))
  }
}

extension AnyBSON: ExpressibleByArrayLiteral
{
  public init(arrayLiteral elements: AnyBSON?...)
  {
    self = .array(elements)
  }
}

extension AnyBSON: Equatable {}

extension AnyBSON: Hashable {}
