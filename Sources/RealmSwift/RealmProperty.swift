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

/**
 A `RealmProperty` instance represents an polymorphic value for supported types.

 To change the underlying value stored by a `RealmProperty` instance, mutate the instance's `value` property.

 - Note:
 An `RealmProperty` should not be declared as `@objc dynamic` on a Realm Object. Use `let` instead.
 */
public final class RealmProperty<Value: RealmPropertyType>: RLMSwiftValueStorage
{
  /**
   Used for getting / setting the underlying value.

    - Usage:
   ```
      class MyObject: Object {
          let myAnyValue = RealmProperty<AnyRealmValue>()
      }
      // Setting
      myObject.myAnyValue.value = .string("hello")
      // Getting
      if case let .string(s) = myObject.myAnyValue.value {
          print(s) // Prints 'Hello'
      }
   ```
   */
  public var value: Value
  {
    get
    {
      staticBridgeCast(fromObjectiveC: RLMGetSwiftValueStorage(self) ?? NSNull())
    }
    set
    {
      RLMSetSwiftValueStorage(self, staticBridgeCast(fromSwift: newValue))
    }
  }

  /// :nodoc:
  @objc override public var description: String
  {
    String(describing: value)
  }
}

extension RealmProperty: Equatable where Value: Equatable
{
  public static func == (lhs: RealmProperty<Value>, rhs: RealmProperty<Value>) -> Bool
  {
    lhs.value == rhs.value
  }
}

extension RealmProperty: Codable where Value: Codable
{
  public convenience init(from decoder: Decoder) throws
  {
    self.init()
    value = try decoder.decodeOptional(Value.self)
  }

  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

/// A protocol describing types that can parameterize a `RealmPropertyType`.
public protocol RealmPropertyType: _ObjcBridgeable, _RealmSchemaDiscoverable {}

extension AnyRealmValue: RealmPropertyType {}
extension Optional: RealmPropertyType where Wrapped: RealmOptionalType & _RealmSchemaDiscoverable {}
