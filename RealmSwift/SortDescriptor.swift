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
 A `SortDescriptor` stores a key path and a sort order for use with `sorted(sortDescriptors:)`. It is similar to
 `NSSortDescriptor`, but supports only the subset of functionality which can be efficiently run by Realm's query engine.
 */
@frozen public struct SortDescriptor
{
  // MARK: Properties

  /// The key path which the sort descriptor orders results by.
  public let keyPath: String

  /// Whether this descriptor sorts in ascending or descending order.
  public let ascending: Bool

  /// Converts the receiver to an `RLMSortDescriptor`.
  var rlmSortDescriptorValue: RLMSortDescriptor
  {
    RLMSortDescriptor(keyPath: keyPath, ascending: ascending)
  }

  // MARK: Initializers

  /**
   Creates a sort descriptor with the given key path and sort order values.

   - parameter keyPath:   The key path which the sort descriptor orders results by.
   - parameter ascending: Whether the descriptor sorts in ascending or descending order.
   */
  public init(keyPath: String, ascending: Bool = true)
  {
    self.keyPath = keyPath
    self.ascending = ascending
  }

  /**
   Creates a sort descriptor with the given key path and sort order values.

   - parameter keyPath:   The key path which the sort descriptor orders results by.
   - parameter ascending: Whether the descriptor sorts in ascending or descending order.
   */
  public init(keyPath: PartialKeyPath<some ObjectBase>, ascending: Bool = true)
  {
    self.keyPath = _name(for: keyPath)
    self.ascending = ascending
  }

  // MARK: Functions

  /// Returns a copy of the sort descriptor with the sort order reversed.
  public func reversed() -> SortDescriptor
  {
    SortDescriptor(keyPath: keyPath, ascending: !ascending)
  }
}

// MARK: CustomStringConvertible

extension SortDescriptor: CustomStringConvertible
{
  /// A human-readable description of the sort descriptor.
  public var description: String
  {
    let direction = ascending ? "ascending" : "descending"
    return "SortDescriptor(keyPath: \(keyPath), direction: \(direction))"
  }
}

// MARK: Equatable

extension SortDescriptor: Equatable
{
  /// Returns whether the two sort descriptors are equal.
  public static func == (lhs: SortDescriptor, rhs: SortDescriptor) -> Bool
  {
    lhs.keyPath == rhs.keyPath &&
      lhs.ascending == rhs.ascending
  }
}

// MARK: StringLiteralConvertible

extension SortDescriptor: ExpressibleByStringLiteral
{
  public typealias UnicodeScalarLiteralType = StringLiteralType
  public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

  /**
   Creates a `SortDescriptor` out of a string literal.

   - parameter stringLiteral: Property name literal.
   */
  public init(stringLiteral value: StringLiteralType)
  {
    self.init(keyPath: value)
  }
}
