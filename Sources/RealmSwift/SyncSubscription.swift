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

////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Combine
import Foundation
import Realm
import Realm.Private

/// An enum representing different states for the Subscription Set.
@frozen public enum SyncSubscriptionState: Equatable
{
  /// The subscription is complete and the server has sent all the data that matched the subscription
  /// queries at the time the subscription set was updated. The server is now in a steady-state
  /// synchronization mode where it will stream update as they come.
  case complete
  /// The subscription encountered an error and synchronization is paused for this Realm. You can
  /// still use the current subscription set to write a subscription.
  case error(Error)
  /// The subscription is persisted locally but not yet processed by the server, which means
  /// the server hasn't yet returned all the data that matched the updated subscription queries.
  case pending
  /// The subscription set has been superseded by an updated one, this typically means that
  /// someone is trying to write a subscription on a different instance of the subscription set.
  /// You should not use a superseded subscription set and instead obtain a new instance of
  /// the subscription set to write a subscription.
  case superseded

  public static func == (lhs: SyncSubscriptionState, rhs: SyncSubscriptionState) -> Bool
  {
    switch (lhs, rhs)
    {
      case (.complete, .complete), (.pending, .pending), (.superseded, .superseded):
        true
      case let (.error(error), .error(error2)):
        error == error2
      default:
        false
    }
  }
}

/**
 `SyncSubscription` is  used to define a Flexible Sync subscription obtained from querying a
 subscription set, which can be used to read or remove/update a committed subscription.
 */
@frozen public struct SyncSubscription
{
  // MARK: Initializers

  fileprivate let _rlmSyncSubscription: RLMSyncSubscription

  fileprivate init(_ rlmSyncSubscription: RLMSyncSubscription)
  {
    _rlmSyncSubscription = rlmSyncSubscription
  }

  /// Name of the subscription, if not specified it will return the value in Query as a String.
  public var name: String?
  {
    _rlmSyncSubscription.name
  }

  /// When the subscription was created. Recorded automatically.
  public var createdAt: Date
  {
    _rlmSyncSubscription.createdAt
  }

  /// When the subscription was last updated. Recorded automatically.
  public var updatedAt: Date
  {
    _rlmSyncSubscription.updatedAt
  }

  /**
   Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
   from the server when committed.

   - warning: This method may only be called during a write subscription block.

   - parameter type: The type of the object to be queried.
   - parameter query: A query which will be used to modify the existing query.
                      If nil it will set the query to get all documents in the collection.
   */
  public func updateQuery<T: Object>(toType _: T.Type, where query: ((Query<T>) -> Query<Bool>)? = nil)
  {
    guard _rlmSyncSubscription.objectClassName == "\(T.self)"
    else
    {
      throwRealmException("Updating a subscription query of a different Object Type is not allowed.")
    }
    _rlmSyncSubscription.update(with: query?(Query()).predicate ?? NSPredicate(format: "TRUEPREDICATE"))
  }

  /**
   Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
   from the server when committed.

   - warning: This method may only be called during a write subscription block.

   - parameter type: The type of the object to be queried.
   - parameter query: A query which will be used to modify the existing query.
   */
  public func updateQuery<T: Object>(toType _: T.Type, where query: (Query<T>) -> Query<Bool>)
  {
    guard _rlmSyncSubscription.objectClassName == "\(T.self)"
    else
    {
      throwRealmException("Updating a subscription query of a different Object Type is not allowed.")
    }
    _rlmSyncSubscription.update(with: query(Query()).predicate)
  }

  /// :nodoc:
  @available(*, unavailable, renamed: "updateQuery", message: "SyncSubscription update is unavailable, please use `.updateQuery` instead.")
  public func update<T: Object>(toType _: T.Type, where _: @escaping (Query<T>) -> Query<Bool>)
  {
    fatalError("This API is unavailable, , please use `.updateQuery` instead.")
  }

  /**
   Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
   from the server when committed.

   - warning: This method may only be called during a write subscription block.

   - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                which will be used to modify the query.
   */
  public func updateQuery(to predicateFormat: String, _ args: Any...)
  {
    _rlmSyncSubscription.update(with: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
  }

  /// :nodoc:
  @available(*, unavailable, renamed: "updateQuery", message: "SyncSubscription update is unavailable, please use `.updateQuery` instead.")
  public func update(to _: String, _: Any...)
  {
    fatalError("This API is unavailable, , please use `.updateQuery` instead.")
  }

  /**
   Updates a Flexible Sync's subscription with an allowed query which will be used to bootstrap data
   from the server when committed.

   - warning: This method may only be called during a write subscription block.

   - parameter predicate: The predicate with which to filter the objects on the server, which
                          will be used to modify the query.
   */
  public func updateQuery(to predicate: NSPredicate)
  {
    _rlmSyncSubscription.update(with: predicate)
  }

  /// :nodoc:
  @available(*, unavailable, renamed: "updateQuery", message: "SyncSubscription update is unavailable, please use `.updateQuery` instead.")
  public func update(to _: NSPredicate)
  {
    fatalError("This API is unavailable, , please use `.updateQuery` instead.")
  }
}

/**
 `SubscriptionQuery` is  used to define an named/unnamed query subscription query, which
 can be added/remove or updated within a write subscription transaction.
 */
@frozen public struct QuerySubscription<T: Object>
{
  // MARK: Internal

  fileprivate let name: String?
  fileprivate var className: String
  fileprivate var predicate: NSPredicate

  /// :nodoc:
  public typealias QueryFunction = (Query<T>) -> Query<Bool>

  /**
   Creates a `QuerySubscription` for the given type.

   - parameter name: Name of the subscription.
   - parameter query: The query for the subscription, if nil it will set the query to all documents for the collection.
   */
  public init(name: String? = nil, query: QueryFunction? = nil)
  {
    self.name = name
    className = "\(T.self)"
    predicate = query?(Query()).predicate ?? NSPredicate(format: "TRUEPREDICATE")
  }

  /**
   Creates a `QuerySubscription` for the given type.

   - parameter name: Name of the subscription.
   - parameter query: The query for the subscription.
   */
  public init(name: String? = nil, query: QueryFunction)
  {
    // This overload is required to make `query` non-escaping, as optional
    // function parameters always are.
    self.name = name
    className = "\(T.self)"
    predicate = query(Query()).predicate
  }

  /**
   Creates a `QuerySubscription` for the given type.

   - parameter name: Name of the subscription.
   - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                which will be used to create the subscription.
   */
  public init(name: String? = nil, where predicateFormat: String, _ args: Any...)
  {
    self.name = name
    className = "\(T.self)"
    predicate = NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args))
  }

  /**
   Creates a `QuerySubscription` for the given type.

   - parameter name: Name of the subscription.
   - parameter predicate: The predicate defining the query used to filter the objects on the server..
   */
  public init(name: String? = nil, where predicate: NSPredicate)
  {
    self.name = name
    className = "\(T.self)"
    self.predicate = predicate
  }
}

/**
 `SyncSubscriptionSet` is  a collection of `SyncSubscription`s. This is the entry point
 for adding and removing `SyncSubscription`s.
 */
@frozen public struct SyncSubscriptionSet
{
  // MARK: Internal

  let rlmSyncSubscriptionSet: RLMSyncSubscriptionSet

  // MARK: Initializers

  init(_ rlmSyncSubscriptionSet: RLMSyncSubscriptionSet)
  {
    self.rlmSyncSubscriptionSet = rlmSyncSubscriptionSet
  }

  /// The number of subscriptions in the subscription set.
  public var count: Int { Int(rlmSyncSubscriptionSet.count) }

  /**
   Synchronously performs any transactions (add/remove/update) to the subscription set within the block.

   - parameter block:      The block containing the subscriptions transactions to perform.
   - parameter onComplete: The block called upon synchronization of subscriptions to the server. Otherwise
                           an `Error`describing what went wrong will be returned by the block
   */
  public func update(_ block: () -> Void, onComplete: (@Sendable (Error?) -> Void)? = nil)
  {
    rlmSyncSubscriptionSet.update(block, onComplete: onComplete)
  }

  /// :nodoc:
  @available(*, unavailable, renamed: "update", message: "SyncSubscriptionSet write is unavailable, please use `.update` instead.")
  public func write(_: () -> Void, onComplete _: ((Error?) -> Void)? = nil)
  {
    fatalError("This API is unavailable, , please use `.update` instead.")
  }

  /// Returns the current state for the subscription set.
  public var state: SyncSubscriptionState
  {
    switch rlmSyncSubscriptionSet.state
    {
      case .pending:
        return .pending
      case .complete:
        return .complete
      case .superseded:
        return .superseded
      case .error:
        return .error(rlmSyncSubscriptionSet.error!)
      @unknown default:
        fatalError()
    }
  }

  /**
   Returns a subscription by the specified name.

   - parameter named: The name of the subscription searching for.
   - returns: A subscription for the given name.
   */
  public func first(named: String) -> SyncSubscription?
  {
    rlmSyncSubscriptionSet.subscription(withName: named).map(SyncSubscription.init)
  }

  /**
   Returns a subscription by the specified query.

   - parameter type: The type of the object to be queried.
   - parameter where: A query builder that produces a subscription which can be used to search
                      the subscription by query and/or name.
   - returns: A query builder that produces a subscription which can used to search for the subscription.
   */
  public func first<T: Object>(ofType _: T.Type, where query: (Query<T>) -> Query<Bool>) -> SyncSubscription?
  {
    rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: query(Query()).predicate).map(SyncSubscription.init)
  }

  /**
   Returns a subscription by the specified query.

   - parameter type: The type of the object to be queried.
   - parameter where: A query builder that produces a subscription which can be used to search
                      the subscription by query and/or name.
   - returns: A query builder that produces a subscription which can used to search for the subscription.
   */
  public func first<T: Object>(ofType _: T.Type, where predicateFormat: String, _ args: Any...) -> SyncSubscription?
  {
    rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args))).map(SyncSubscription.init)
  }

  /**
   Returns a subscription by the specified query.

   - parameter type: The type of the object to be queried.
   - parameter where: A query builder that produces a subscription which can be used to search
                      the subscription by query and/or name.
   - returns: A query builder that produces a subscription which can used to search for the subscription.
   */
  public func first<T: Object>(ofType _: T.Type, where predicate: NSPredicate) -> SyncSubscription?
  {
    rlmSyncSubscriptionSet.subscription(withClassName: "\(T.self)", predicate: predicate).map(SyncSubscription.init)
  }

  /**
   Appends one or several subscriptions to the subscription set.

   - warning: This method may only be called during a write subscription block.

   - parameter subscriptions: The subscriptions to be added to the subscription set.
   */
  public func append<T: Object>(_ subscriptions: QuerySubscription<T>...)
  {
    subscriptions.forEach
    { subscription in
      rlmSyncSubscriptionSet.addSubscription(withClassName: subscription.className,
                                             subscriptionName: subscription.name,
                                             predicate: subscription.predicate)
    }
  }

  /**
   Removes a subscription with the specified query.

   - warning: This method may only be called during a write subscription block.

   - parameter type: The type of the object to be removed.
   - parameter to: A query for the subscription to be removed from the subscription set.
   */
  public func remove<T: Object>(ofType _: T.Type, _ query: @escaping (Query<T>) -> Query<Bool>)
  {
    rlmSyncSubscriptionSet.removeSubscription(withClassName: "\(T.self)",
                                              predicate: query(Query()).predicate)
  }

  /**
   Removes a subscription with the specified query.

   - warning: This method may only be called during a write subscription block.

   - parameter type: The type of the object to be removed.
   - parameter predicateFormat: A predicate format string, optionally followed by a variable number of arguments,
                                which will be used to identify the subscription to be removed.
   */
  public func remove<T: Object>(ofType _: T.Type, where predicateFormat: String, _ args: Any...)
  {
    rlmSyncSubscriptionSet.removeSubscription(withClassName: "\(T.self)",
                                              predicate: NSPredicate(format: predicateFormat, argumentArray: unwrapOptionals(in: args)))
  }

  /**
   Removes a subscription with the specified query.

   - warning: This method may only be called during a write subscription block.

   - parameter type: The type of the object to be removed.
   - parameter predicate: The predicate which will be used to identify the subscription to be removed.
   */
  public func remove<T: Object>(ofType _: T.Type, where predicate: NSPredicate)
  {
    rlmSyncSubscriptionSet.removeSubscription(withClassName: "\(T.self)",
                                              predicate: predicate)
  }

  /**
   Removes one or several subscriptions from the subscription set.

   - warning: This method may only be called during a write subscription block.

   - parameter subscription: The subscription to be removed from the subscription set.
   */
  public func remove(_ subscriptions: SyncSubscription...)
  {
    subscriptions.forEach
    { subscription in
      rlmSyncSubscriptionSet.remove(subscription._rlmSyncSubscription)
    }
  }

  /**
   Removes a subscription with the specified name from the subscription set.

   - warning: This method may only be called during a write subscription block.

   - parameter named: The name of the subscription to be removed from the subscription set.
   */
  public func remove(named: String)
  {
    rlmSyncSubscriptionSet.removeSubscription(withName: named)
  }

  /**
   Removes all subscriptions from the subscription set.

   - parameter unnamedOnly: If true, only unnamed subscriptions are removed.
   - warning: This method may only be called during a write subscription block.
   - warning: Removing all subscriptions will result in an error if no new subscription is added. Server should
              acknowledge at least one subscription.
   */
  public func removeAll(unnamedOnly: Bool = false)
  {
    if unnamedOnly
    {
      rlmSyncSubscriptionSet.removeAllUnnamedSubscriptions()
    }
    else
    {
      rlmSyncSubscriptionSet.removeAllSubscriptions()
    }
  }

  /**
   Removes zero or none subscriptions of the given type from the subscription set.

   - warning: This method may only be called during a write subscription block.

   - parameter type: The type of the objects to be removed.
   */
  public func removeAll(ofType type: (some Object).Type)
  {
    rlmSyncSubscriptionSet.removeAllSubscriptions(withClassName: type.className())
  }

  // MARK: Subscription Retrieval

  /**
   Returns the subscription at the given `position`.

   - parameter position: The index for the resulting subscription.
   */
  public subscript(position: Int) -> SyncSubscription?
  {
    throwForNegativeIndex(position)
    return rlmSyncSubscriptionSet.object(at: UInt(position)).map { SyncSubscription($0) }
  }

  /// Returns the first object in the SyncSubscription list, or `nil` if the subscriptions are empty.
  public var first: SyncSubscription?
  {
    rlmSyncSubscriptionSet.firstObject().map { SyncSubscription($0) }
  }

  /// Returns the last object in the SyncSubscription list, or `nil` if the subscriptions are empty.
  public var last: SyncSubscription?
  {
    rlmSyncSubscriptionSet.lastObject().map { SyncSubscription($0) }
  }
}

extension SyncSubscriptionSet: Sequence
{
  // MARK: Sequence Support

  /// Returns a `SyncSubscriptionSetIterator` that yields successive elements in the subscription collection.
  public func makeIterator() -> SyncSubscriptionSetIterator
  {
    SyncSubscriptionSetIterator(rlmSyncSubscriptionSet)
  }
}

/**
 This struct enables sequence-style enumeration for `SyncSubscriptionSet`.
 */
@frozen public struct SyncSubscriptionSetIterator: IteratorProtocol
{
  private let rlmSubscriptionSet: RLMSyncSubscriptionSet
  private var index: Int = -1

  init(_ rlmSubscriptionSet: RLMSyncSubscriptionSet)
  {
    self.rlmSubscriptionSet = rlmSubscriptionSet
  }

  private func nextIndex(for index: Int?) -> Int?
  {
    if let index, index < rlmSubscriptionSet.count - 1
    {
      return index + 1
    }
    return nil
  }

  public mutating func next() -> RLMSyncSubscription?
  {
    if let index = nextIndex(for: index)
    {
      self.index = index
      return rlmSubscriptionSet.object(at: UInt(index))
    }
    return nil
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension SyncSubscriptionSet
{
  /**
   Creates and commits a transaction, updating the subscription set,
   this will continue when the server acknowledge and all the data associated with this
   collection of subscriptions is synced.

   - parameter block: The block containing the subscriptions transactions to perform.

   - throws: An `NSError` if the subscription set state changes to an error state or there is and error while                           committing any changes to the subscriptions.
   */
  @MainActor
  func update(_ block: () -> Void) async throws
  {
    try await rlmSyncSubscriptionSet.update(block)
  }

  /// :nodoc:
  @available(*, unavailable, renamed: "update", message: "SyncSubscriptionSet write is unavailable, please use `.update` instead.")
  func write(_: () -> Void) async throws
  {
    fatalError("This API is unavailable, , please use `.update` instead.")
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension SyncSubscriptionSet
{
  /**
   Creates and commit a transaction, updating the subscription set,
   this will return success when the server acknowledge and all the data associated with this
   collection of subscriptions is synced.

   - parameter block: The block containing the subscriptions transactions to perform.
   - returns: A publisher that eventually returns `Result.success` or `Error`.
   */
  func updateSubscriptions(_ block: @escaping (() -> Void)) -> Future<Void, Error>
  {
    promisify
    {
      update(block, onComplete: $0)
    }
  }
}
