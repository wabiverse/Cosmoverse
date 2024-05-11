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

/// A type which can be bridged to and from Objective-C.
///
/// Do not use this protocol or the functions it adds directly.
public protocol _ObjcBridgeable
{
  static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self?
  var _rlmObjcValue: Any { get }
}

/// A type where the default logic suffices for bridging and we don't need to do anything special.
protocol DefaultObjcBridgeable: _ObjcBridgeable {}
extension DefaultObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any, insideOptional _: Bool) -> Self? { value as? Self }
  public var _rlmObjcValue: Any { self }
}

/// A type which needs custom logic, but doesn't care if it's being bridged inside an Optional
protocol BuiltInObjcBridgeable: _ObjcBridgeable
{
  static func _rlmFromObjc(_ value: Any) -> Self?
}

extension BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any, insideOptional _: Bool) -> Self?
  {
    _rlmFromObjc(value)
  }
}

extension Bool: DefaultObjcBridgeable {}
extension Int: DefaultObjcBridgeable {}
extension Double: DefaultObjcBridgeable {}
extension Date: DefaultObjcBridgeable {}
extension String: DefaultObjcBridgeable {}
extension Data: DefaultObjcBridgeable {}
extension ObjectId: DefaultObjcBridgeable {}
extension UUID: DefaultObjcBridgeable {}
extension NSNumber: DefaultObjcBridgeable {}
extension NSDate: DefaultObjcBridgeable {}

extension ObjectBase: BuiltInObjcBridgeable
{
  public class func _rlmFromObjc(_ value: Any) -> Self?
  {
    if let value = value as? Self
    {
      return value
    }
    if Self.self === DynamicObject.self, let object = value as? ObjectBase
    {
      // Without `as AnyObject` this will produce a warning which incorrectly
      // claims it could be replaced with `unsafeDowncast()`
      return unsafeBitCast(object as AnyObject, to: Self.self)
    }
    return nil
  }

  public var _rlmObjcValue: Any { self }
}

/// `NSNumber as? T` coerces values which can't be exact represented for some
/// types and fails for others. We want to always coerce, for backwards
/// compatibility if nothing else.
extension Float: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? NSNumber)?.floatValue
  }

  public var _rlmObjcValue: Any
  {
    NSNumber(value: self)
  }
}

extension Int8: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? NSNumber)?.int8Value
  }

  public var _rlmObjcValue: Any
  {
    // Promote to Int before boxing as otherwise 0 and 1 will get treated
    // as Bool instead.
    NSNumber(value: Int16(self))
  }
}

extension Int16: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? NSNumber)?.int16Value
  }

  public var _rlmObjcValue: Any
  {
    NSNumber(value: self)
  }
}

extension Int32: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? NSNumber)?.int32Value
  }

  public var _rlmObjcValue: Any
  {
    NSNumber(value: self)
  }
}

extension Int64: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? NSNumber)?.int64Value
  }

  public var _rlmObjcValue: Any
  {
    NSNumber(value: self)
  }
}

extension Optional: BuiltInObjcBridgeable, _ObjcBridgeable where Wrapped: _ObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    // ?? here gives the nonsensical error "Left side of nil coalescing operator '??' has non-optional type 'Wrapped?', so the right side is never used"
    if let value = Wrapped._rlmFromObjc(value, insideOptional: true)
    {
      return .some(value)
    }
    // We have a double-optional here and need to explicitly specify that we
    // successfully converted to `nil`, as opposed to failing to bridge.
    return .some(Self.none)
  }

  public var _rlmObjcValue: Any
  {
    if let value = self
    {
      return value._rlmObjcValue
    }
    return NSNull()
  }
}

extension Decimal128: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Decimal128?
  {
    if let value = value as? Decimal128
    {
      return .some(value)
    }
    if let number = value as? NSNumber
    {
      return Decimal128(number: number)
    }
    if let str = value as? String
    {
      return .some((try? Decimal128(string: str)) ?? Decimal128("nan"))
    }
    return .none
  }

  public var _rlmObjcValue: Any
  {
    self
  }
}

extension AnyRealmValue: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    if let any = value as? Self
    {
      return any
    }
    if let any = value as? RLMValue
    {
      return ObjectiveCSupport.convert(value: any)
    }
    return Self?.none // We need to explicitly say which .none we want here
  }

  public var _rlmObjcValue: Any
  {
    ObjectiveCSupport.convert(value: self) ?? NSNull()
  }
}

// MARK: - Collections

extension Map: BuiltInObjcBridgeable
{
  public var _rlmObjcValue: Any { _rlmCollection }
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? RLMCollection).map(Self.init(collection:))
  }
}

public extension RealmCollectionImpl
{
  var _rlmObjcValue: Any { collection }
  static func _rlmFromObjc(_ value: Any, insideOptional _: Bool) -> Self?
  {
    (value as? RLMCollection).map(Self.init(collection:))
  }
}

extension LinkingObjects: _ObjcBridgeable {}
extension Results: _ObjcBridgeable {}
extension AnyRealmCollection: _ObjcBridgeable {}
extension List: _ObjcBridgeable {}
extension MutableSet: _ObjcBridgeable {}

extension SectionedResults: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any, insideOptional _: Bool) -> Self?
  {
    (value as? RLMSectionedResults<RLMValue, RLMValue>).map(Self.init(rlmSectionedResult:))
  }

  public var _rlmObjcValue: Any
  {
    collection
  }
}

extension ResultsSection: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any, insideOptional _: Bool) -> Self?
  {
    (value as? RLMSection<RLMValue, RLMValue>).map(Self.init(rlmSectionedResult:))
  }

  public var _rlmObjcValue: Any
  {
    collection
  }
}

extension RLMSwiftCollectionBase: Equatable
{
  public static func == (lhs: RLMSwiftCollectionBase, rhs: RLMSwiftCollectionBase) -> Bool
  {
    lhs.isEqual(rhs)
  }
}

extension Projection: BuiltInObjcBridgeable
{
  public static func _rlmFromObjc(_ value: Any) -> Self?
  {
    (value as? Root).map(Self.init(projecting:))
  }

  public var _rlmObjcValue: Any
  {
    rootObject
  }
}

public protocol _PossiblyAggregateable: _ObjcBridgeable
{
  associatedtype PersistedType
}

extension NSDate: _PossiblyAggregateable {}
extension NSNumber: _PossiblyAggregateable {}
