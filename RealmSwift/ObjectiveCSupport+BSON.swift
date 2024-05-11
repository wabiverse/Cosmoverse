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

/**
 :nodoc:
 **/
public extension ObjectiveCSupport
{
  // FIXME: remove these and rename convertBson to convert on the next major
  // version bump
  static func convert(object: AnyBSON?) -> RLMBSON?
  {
    if let converted = object.map(convertBson), !(converted is NSNull)
    {
      return converted
    }
    return nil
  }

  static func convert(object: RLMBSON?) -> AnyBSON?
  {
    if let object
    {
      let converted = convertBson(object: object)
      if converted == .null
      {
        return nil
      }
      return converted
    }
    return nil
  }

  static func convert(_ object: Document) -> [String: RLMBSON]
  {
    object.reduce(into: [String: RLMBSON]())
    { (result: inout [String: RLMBSON], kvp) in
      result[kvp.key] = kvp.value.map(convertBson) ?? NSNull()
    }
  }

  /// Convert an `AnyBSON` to a `RLMBSON`.
  static func convertBson(object: AnyBSON) -> RLMBSON
  {
    switch object
    {
      case let .int32(val):
        val as NSNumber
      case let .int64(val):
        val as NSNumber
      case let .double(val):
        val as NSNumber
      case let .string(val):
        val as NSString
      case let .binary(val):
        val as NSData
      case let .datetime(val):
        val as NSDate
      case let .timestamp(val):
        val as NSDate
      case let .decimal128(val):
        val as RLMDecimal128
      case let .objectId(val):
        val as RLMObjectId
      case let .document(val):
        convert(val) as NSDictionary
      case let .array(val):
        val.map { $0.map(convertBson) } as NSArray
      case .maxKey:
        MaxKey()
      case .minKey:
        MinKey()
      case let .regex(val):
        val
      case let .bool(val):
        val as NSNumber
      case let .uuid(val):
        val as NSUUID
      case .null:
        NSNull()
    }
  }

  static func convert(_ object: [String: RLMBSON]) -> Document
  {
    object.mapValues { convert(object: $0) }
  }

  /// Convert a `RLMBSON` to an `AnyBSON`.
  static func convertBson(object bson: RLMBSON) -> AnyBSON?
  {
    switch bson.__bsonType
    {
      case .null:
        return .null
      case .int32:
        guard let val = bson as? NSNumber
        else
        {
          return nil
        }
        return .int32(Int32(val.intValue))
      case .int64:
        guard let val = bson as? NSNumber
        else
        {
          return nil
        }
        return .int64(Int64(val.int64Value))
      case .bool:
        guard let val = bson as? NSNumber
        else
        {
          return nil
        }
        return .bool(val.boolValue)
      case .double:
        guard let val = bson as? NSNumber
        else
        {
          return nil
        }
        return .double(val.doubleValue)
      case .string:
        guard let val = bson as? NSString
        else
        {
          return nil
        }
        return .string(val as String)
      case .binary:
        guard let val = bson as? NSData
        else
        {
          return nil
        }
        return .binary(val as Data)
      case .timestamp:
        guard let val = bson as? NSDate
        else
        {
          return nil
        }
        return .timestamp(val as Date)
      case .datetime:
        guard let val = bson as? NSDate
        else
        {
          return nil
        }
        return .datetime(val as Date)
      case .objectId:
        guard let val = bson as? RLMObjectId,
              let oid = try? ObjectId(string: val.stringValue)
        else
        {
          return nil
        }
        return .objectId(oid)
      case .decimal128:
        guard let val = bson as? RLMDecimal128
        else
        {
          return nil
        }
        return .decimal128(Decimal128(stringLiteral: val.stringValue))
      case .regularExpression:
        guard let val = bson as? NSRegularExpression
        else
        {
          return nil
        }
        return .regex(val)
      case .maxKey:
        return .maxKey
      case .minKey:
        return .minKey
      case .document:
        guard let val = bson as? [String: RLMBSON]
        else
        {
          return nil
        }
        return .document(convert(val))
      case .array:
        guard let val = bson as? [RLMBSON?]
        else
        {
          return nil
        }
        return .array(val.compactMap
        {
          if let value = $0
          {
            return convertBson(object: value)
          }
          return .null
        }.map { (v: AnyBSON) -> AnyBSON? in v == .null ? nil : v })
      case .UUID:
        guard let val = bson as? NSUUID
        else
        {
          return nil
        }
        return .uuid(val as UUID)
      default:
        return nil
    }
  }
}
