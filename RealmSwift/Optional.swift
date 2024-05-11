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

/// A protocol describing types that can parameterize a `RealmOptional`.
public protocol RealmOptionalType: _ObjcBridgeable
{}

public extension RealmOptionalType
{
  /// :nodoc:
  static func className() -> String
  {
    ""
  }
}

extension Int: RealmOptionalType {}
extension Int8: RealmOptionalType {}
extension Int16: RealmOptionalType {}
extension Int32: RealmOptionalType {}
extension Int64: RealmOptionalType {}
extension Float: RealmOptionalType {}
extension Double: RealmOptionalType {}
extension Bool: RealmOptionalType {}

/**
 A `RealmOptional` instance represents an optional value for types that can't be
 directly declared as `@objc` in Swift, such as `Int`, `Float`, `Double`, and `Bool`.

 To change the underlying value stored by a `RealmOptional` instance, mutate the instance's `value` property.
 */
@available(*, deprecated, renamed: "RealmProperty", message: "RealmOptional<T> has been deprecated, use RealmProperty<T?> instead.")
public final class RealmOptional<Value: RealmOptionalType>: RLMSwiftValueStorage
{
  /// The value the optional represents.
  public var value: Value?
  {
    get
    {
      RLMGetSwiftValueStorage(self).map(staticBridgeCast)
    }
    set
    {
      RLMSetSwiftValueStorage(self, newValue.map(staticBridgeCast))
    }
  }

  /**
   Creates a `RealmOptional` instance encapsulating the given default value.

   - parameter value: The value to store in the optional, or `nil` if not specified.
   */
  public init(_ value: Value? = nil)
  {
    super.init()
    self.value = value
  }
}

@available(*, deprecated, message: "RealmOptional has been deprecated, use RealmProperty<T?> instead.")
extension RealmOptional: Equatable where Value: Equatable
{
  public static func == (lhs: RealmOptional<Value>, rhs: RealmOptional<Value>) -> Bool
  {
    lhs.value == rhs.value
  }
}

@available(*, deprecated, message: "RealmOptional has been deprecated, use RealmProperty<T?> instead.")
extension RealmOptional: Codable where Value: Codable, Value: _RealmSchemaDiscoverable
{
  public convenience init(from decoder: Decoder) throws
  {
    self.init()
    // `try decoder.singleValueContainer().decode(Value?.self)` incorrectly
    // rejects null values: https://bugs.swift.org/browse/SR-7404
    value = try decoder.decodeOptional(Value?.self)
  }

  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

protocol RealmOptionalProtocol {}
@available(*, deprecated, message: "RealmOptional has been deprecated, use RealmProperty<T?> instead.")
extension RealmOptional: RealmOptionalProtocol {}

extension Decoder
{
  func decodeOptional<T: _RealmSchemaDiscoverable>(_: T.Type) throws -> T where T: Decodable
  {
    let container = try singleValueContainer()
    if container.decodeNil()
    {
      if let type = T.self as? _ObjcBridgeable.Type, let value = type._rlmFromObjc(NSNull())
      {
        return value as! T
      }
      throw DecodingError.typeMismatch(T.self, .init(codingPath: codingPath, debugDescription: "Cannot convert nil to \(T.self)"))
    }
    return try container.decode(T.self)
  }
}
