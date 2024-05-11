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
import Realm

public extension ObjectiveCSupport
{
  /// Convert an object boxed in `AnyRealmValue` to its
  /// Objective-C representation.
  /// - Parameter value: The AnyRealmValue with the object.
  /// - Returns: Conversion of `value` to its Objective-C representation.
  static func convert(value: AnyRealmValue?) -> RLMValue?
  {
    switch value
    {
      case let .int(i):
        i as NSNumber
      case let .bool(b):
        b as NSNumber
      case let .float(f):
        f as NSNumber
      case let .double(f):
        f as NSNumber
      case let .string(s):
        s as NSString
      case let .data(d):
        d as NSData
      case let .date(d):
        d as NSDate
      case let .objectId(o):
        o as RLMObjectId
      case let .decimal128(o):
        o as RLMDecimal128
      case let .uuid(u):
        u as NSUUID
      case let .object(o):
        o
      default:
        nil
    }
  }

  /// Takes an RLMValue, converts it to its Swift type and
  /// stores it in `AnyRealmValue`.
  /// - Parameter value: The RLMValue.
  /// - Returns: The converted RLMValue type as an AnyRealmValue enum.
  static func convert(value: RLMValue?) -> AnyRealmValue
  {
    guard let value
    else
    {
      return .none
    }

    switch value.rlm_valueType
    {
      case RLMPropertyType.int:
        guard let val = value as? NSNumber
        else
        {
          return .none
        }
        return .int(val.intValue)
      case RLMPropertyType.bool:
        guard let val = value as? NSNumber
        else
        {
          return .none
        }
        return .bool(val.boolValue)
      case RLMPropertyType.float:
        guard let val = value as? NSNumber
        else
        {
          return .none
        }
        return .float(val.floatValue)
      case RLMPropertyType.double:
        guard let val = value as? NSNumber
        else
        {
          return .none
        }
        return .double(val.doubleValue)
      case RLMPropertyType.string:
        guard let val = value as? String
        else
        {
          return .none
        }
        return .string(val)
      case RLMPropertyType.data:
        guard let val = value as? Data
        else
        {
          return .none
        }
        return .data(val)
      case RLMPropertyType.date:
        guard let val = value as? Date
        else
        {
          return .none
        }
        return .date(val)
      case RLMPropertyType.objectId:
        guard let val = value as? ObjectId
        else
        {
          return .none
        }
        return .objectId(val)
      case RLMPropertyType.decimal128:
        guard let val = value as? Decimal128
        else
        {
          return .none
        }
        return .decimal128(val)
      case RLMPropertyType.UUID:
        guard let val = value as? UUID
        else
        {
          return .none
        }
        return .uuid(val)
      case RLMPropertyType.object:
        guard let val = value as? Object
        else
        {
          return .none
        }
        return .object(val)
      default:
        return .none
    }
  }
}
