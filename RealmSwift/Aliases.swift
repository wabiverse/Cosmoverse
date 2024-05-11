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
import Realm.Swift

// These types don't change when wrapping in Swift
// so we just typealias them to remove the 'RLM' prefix

// MARK: Aliases

/**
 `PropertyType` is an enum describing all property types supported in Realm models.

 For more information, see [Object Models and Schemas](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/model-data/object-models/).

 ### Primitive types

 * `Int`
 * `Bool`
 * `Float`
 * `Double`

 ### Object types

 * `String`
 * `Data`
 * `Date`
 * `Decimal128`
 * `ObjectId`

 ### Relationships: Array (in Swift, `List`) and `Object` types

 * `Object`
 * `Array`
 */
public typealias PropertyType = RLMPropertyType

/**
 An opaque token which is returned from methods which subscribe to changes to a Realm.

 - see: `Realm.observe(_:)`
 */
public typealias NotificationToken = RLMNotificationToken

/// :nodoc:
public typealias ObjectBase = RLMObjectBase
extension ObjectBase
{
  func _observe<T: ObjectBase>(keyPaths: [String]? = nil,
                               on queue: DispatchQueue? = nil,
                               _ block: @escaping (ObjectChange<T>) -> Void) -> NotificationToken
  {
    RLMObjectBaseAddNotificationBlock(self, keyPaths, queue)
    { object, names, oldValues, newValues, error in
      assert(error == nil)
      block(.init(object: object as? T, names: names, oldValues: oldValues, newValues: newValues))
    }
  }

  func _observe<T: ObjectBase>(keyPaths: [String]? = nil,
                               on queue: DispatchQueue? = nil,
                               _ block: @escaping (T?) -> Void) -> NotificationToken
  {
    RLMObjectBaseAddNotificationBlock(self, keyPaths, queue)
    { object, _, _, _, _ in
      block(object as? T)
    }
  }

  func _observe(keyPaths: [String]? = nil,
                on queue: DispatchQueue? = nil,
                _ block: @escaping () -> Void) -> NotificationToken
  {
    RLMObjectBaseAddNotificationBlock(self, keyPaths, queue)
    { _, _, _, _, _ in
      block()
    }
  }

  @available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
  func _observe<A: Actor, T: ObjectBase>(
    keyPaths: [String]? = nil, on actor: isolated A,
    _ block: @Sendable @escaping (isolated A, ObjectChange<T>) -> Void
  ) async -> NotificationToken
  {
    let token = RLMObjectNotificationToken()
    token.observe(self, keyPaths: keyPaths)
    { object, names, oldValues, newValues, error in
      assert(error == nil)
      assumeOnActorExecutor(actor)
      { actor in
        block(actor, .init(object: object as? T, names: names,
                           oldValues: oldValues, newValues: newValues))
      }
    }
    await withTaskCancellationHandler(operation: token.registrationComplete,
                                      onCancel: { token.invalidate() })
    return token
  }
}
