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
 A 12-byte (probably) unique object identifier.

 ObjectIds are similar to a GUID or a UUID, and can be used to uniquely identify objects without a centralized ID generator. An ObjectID consists of:

 1. A 4 byte timestamp measuring the creation time of the ObjectId in seconds since the Unix epoch.
 2. A 5 byte random value
 3. A 3 byte counter, initialized to a random value.

 ObjectIds are intended to be fast to generate. Sorting by an ObjectId field will typically result in the objects being sorted in creation order.
 */
@objc(RealmSwiftObjectId)
public final class ObjectId: RLMObjectId, Decodable, @unchecked Sendable
{
  // MARK: Initializers

  /// Creates a new zero-initialized ObjectId.
  override public required init()
  {
    super.init()
  }

  /// Creates a new randomly-initialized ObjectId.
  override public class func generate() -> ObjectId
  {
    unsafeDowncast(super.generate(), to: ObjectId.self)
  }

  /// Creates a new ObjectId from the given 24-byte hexadecimal string.
  ///
  /// Throws if the string is not 24 characters or contains any characters other than 0-9a-fA-F.
  /// - Parameter string: The string to parse.
  override public required init(string: String) throws
  {
    try super.init(string: string)
  }

  /// Creates a new ObjectId using the given date, machine identifier, process identifier.
  ///
  /// - Parameters:
  ///   - timestamp: A timestamp as NSDate.
  ///   - machineId: The machine identifier.
  ///   - processId: The process identifier.
  public required init(timestamp: Date, machineId: Int, processId: Int)
  {
    super.init(timestamp: timestamp,
               machineIdentifier: Int32(machineId),
               processIdentifier: Int32(processId))
  }

  /// Creates a new ObjectId from the given 24-byte hexadecimal static string.
  ///
  /// Aborts if the string is not 24 characters or contains any characters other than 0-9a-fA-F. Use the initializer which takes a String to handle invalid strings at runtime.
  public required init(_ str: StaticString)
  {
    try! super.init(string: str.withUTF8Buffer { String(decoding: $0, as: UTF8.self) })
  }

  /// Creates a new ObjectId by decoding from the given decoder.
  ///
  /// This initializer throws an error if reading from the decoder fails, or
  /// if the data read is corrupted or otherwise invalid.
  ///
  /// - Parameter decoder: The decoder to read data from.
  public required init(from decoder: Decoder) throws
  {
    let container = try decoder.singleValueContainer()
    try super.init(string: container.decode(String.self))
  }
}

extension ObjectId: Encodable
{
  /// Encodes this ObjectId into the given encoder.
  ///
  /// This function throws an error if the given encoder is unable to encode a string.
  ///
  /// - Parameter encoder: The encoder to write data to.
  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.singleValueContainer()
    try container.encode(stringValue)
  }
}

extension ObjectId: Comparable
{
  /// Returns a Boolean value indicating whether the value of the first
  /// argument is less than that of the second argument.
  ///
  /// - Parameters:
  ///   - lhs: An ObjectId value to compare.
  ///   - rhs: Another ObjectId value to compare.
  public static func < (lhs: ObjectId, rhs: ObjectId) -> Bool
  {
    lhs.isLessThan(rhs)
  }

  /// Returns a Boolean value indicating whether the ObjectId of the first
  /// argument is less than or equal to that of the second argument.
  ///
  /// - Parameters:
  ///   - lhs: An ObjectId value to compare.
  ///   - rhs: Another ObjectId value to compare.
  public static func <= (lhs: ObjectId, rhs: ObjectId) -> Bool
  {
    lhs.isLessThanOrEqual(to: rhs)
  }

  /// Returns a Boolean value indicating whether the ObjectId of the first
  /// argument is greater than or equal to that of the second argument.
  ///
  /// - Parameters:
  ///   - lhs: An ObjectId value to compare.
  ///   - rhs: Another ObjectId value to compare.
  public static func >= (lhs: ObjectId, rhs: ObjectId) -> Bool
  {
    lhs.isGreaterThanOrEqual(to: rhs)
  }

  /// Returns a Boolean value indicating whether the ObjectId of the first
  /// argument is greater than that of the second argument.
  ///
  /// - Parameters:
  ///   - lhs: An ObjectId value to compare.
  ///   - rhs: Another ObjectId value to compare.
  public static func > (lhs: ObjectId, rhs: ObjectId) -> Bool
  {
    lhs.isGreaterThan(rhs)
  }
}
