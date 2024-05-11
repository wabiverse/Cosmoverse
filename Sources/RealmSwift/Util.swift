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
import os.log
import Realm

#if BUILDING_REALM_SWIFT_TESTS
  import RealmSwift
#endif

// MARK: Internal Helpers

/// Swift 3.1 provides fixits for some of our uses of unsafeBitCast
/// to use unsafeDowncast instead, but the bitcast is required.
func noWarnUnsafeBitCast<U>(_ x: some Any, to type: U.Type) -> U
{
  unsafeBitCast(x, to: type)
}

/// Given a list of `Any`-typed varargs, unwrap any optionals and
/// replace them with the underlying value or NSNull.
func unwrapOptionals(in varargs: [Any]) -> [Any]
{
  varargs.map
  { arg in
    if let someArg = arg as Any?
    {
      return someArg
    }
    return NSNull()
  }
}

func notFoundToNil(index: UInt) -> Int?
{
  if index == UInt(NSNotFound)
  {
    return nil
  }
  return Int(index)
}

func throwRealmException(_ message: String, userInfo: [AnyHashable: Any]? = nil) -> Never
{
  NSException(name: NSExceptionName(rawValue: RLMExceptionName), reason: message, userInfo: userInfo).raise()
  fatalError() // unreachable
}

func throwForNegativeIndex(_ int: Int, parameterName: String = "index")
{
  if int < 0
  {
    throwRealmException("Cannot pass a negative value for '\(parameterName)'.")
  }
}

func gsub(pattern: String, template: String, string: String, error _: NSErrorPointer = nil) -> String?
{
  let regex = try? NSRegularExpression(pattern: pattern, options: [])
  return regex?.stringByReplacingMatches(in: string, options: [],
                                         range: NSRange(location: 0, length: string.utf16.count),
                                         withTemplate: template)
}

extension ObjectBase
{
  /// Must *only* be used to call Realm Objective-C APIs that are exposed on `RLMObject`
  /// but actually operate on `RLMObjectBase`. Do not expose cast value to user.
  func unsafeCastToRLMObject() -> RLMObject
  {
    noWarnUnsafeBitCast(self, to: RLMObject.self)
  }
}

func coerceToNil(_ value: Any) -> Any?
{
  if value is NSNull
  {
    return nil
  }
  // nil in Any is bridged to obj-c as NSNull. In the obj-c code we usually
  // convert NSNull back to nil, which ends up as Optional<Any>.none
  if case Optional<Any>.none = value
  {
    return nil
  }
  return value
}

// MARK: CustomObjectiveCBridgeable

extension _ObjcBridgeable
{
  static func _rlmFromObjc(_ value: Any) -> Self? { _rlmFromObjc(value, insideOptional: false) }
}

/// :nodoc:
public func dynamicBridgeCast<T>(fromObjectiveC x: Any) -> T
{
  if let bridged = failableDynamicBridgeCast(fromObjectiveC: x) as T?
  {
    return bridged
  }
  fatalError("Could not convert value '\(x)' to type '\(T.self)'")
}

/// :nodoc:
@usableFromInline
func failableDynamicBridgeCast<T>(fromObjectiveC x: Any) -> T?
{
  if let bridgeableType = T.self as? _ObjcBridgeable.Type
  {
    return bridgeableType._rlmFromObjc(x).flatMap { $0 as? T }
  }
  if let value = x as? T
  {
    return value
  }
  return nil
}

/// :nodoc:
public func dynamicBridgeCast(fromSwift x: some Any) -> Any
{
  if let x = x as? _ObjcBridgeable
  {
    return x._rlmObjcValue
  }
  return x
}

@usableFromInline
func staticBridgeCast(fromSwift x: some _ObjcBridgeable) -> Any
{
  x._rlmObjcValue
}

@usableFromInline
func staticBridgeCast<T: _ObjcBridgeable>(fromObjectiveC x: Any) -> T
{
  if let value = T._rlmFromObjc(x)
  {
    return value
  }
  throwRealmException("Could not convert value '\(x)' to type '\(T.self)'.")
}

@usableFromInline
func failableStaticBridgeCast<T: _ObjcBridgeable>(fromObjectiveC x: Any) -> T?
{
  T._rlmFromObjc(x)
}

func logRuntimeIssue(_ message: StaticString)
{
  if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
  {
    // Reporting a runtime issue to Xcode requires pretending to be
    // one of the system libraries which are allowed to do so. We do
    // this by looking up a symbol defined by SwiftUI, getting the
    // dso information from that, and passing that to os_log() to
    // claim that we're SwiftUI. As this is obviously not a particularly legal thing to do, we only do it in debug and simulator builds.
    var dso = #dsohandle
    #if DEBUG || targetEnvironment(simulator)
      let sym = dlsym(dlopen(nil, RTLD_LAZY), "$s7SwiftUI3AppMp")
      var info = Dl_info()
      dladdr(sym, &info)
      if let base = info.dli_fbase
      {
        dso = UnsafeRawPointer(base)
      }
    #endif
    let log = OSLog(subsystem: "com.apple.runtime-issues", category: "Realm")
    os_log(.fault, dso: dso, log: log, message)
  }
  else
  {
    print(message)
  }
}

@_unavailableFromAsync
func assumeOnMainActorExecutor<T>(_ operation: @MainActor () throws -> T,
                                  file: StaticString = #fileID, line: UInt = #line) rethrows -> T
{
  if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
  {
    return try MainActor.assumeIsolated(operation)
  }

  precondition(Thread.isMainThread, file: file, line: line)
  return try withoutActuallyEscaping(operation)
  { fn in
    try unsafeBitCast(fn, to: (() throws -> T).self)()
  }
}

@_unavailableFromAsync
@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
func assumeOnActorExecutor<A: Actor, T>(_ actor: A,
                                        _ operation: (isolated A) throws -> T) rethrows -> T
{
  if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
  {
    return try actor.assumeIsolated(operation)
  }

  return try withoutActuallyEscaping(operation)
  { fn in
    try unsafeBitCast(fn, to: ((A) throws -> T).self)(actor)
  }
}
