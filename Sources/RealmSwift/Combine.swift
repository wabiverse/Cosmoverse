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

import Combine
import Realm
import Realm.Private

// MARK: - Identifiable

/// A protocol which defines a default identity for Realm Objects
///
/// Declaring your Object subclass as conforming to this protocol will supply
/// a default implementation for `Identifiable`'s `id` which works for Realm
/// Objects:
///
///     // Automatically conforms to `Identifiable`
///     class MyObjectType: Object, ObjectKeyIdentifiable {
///         // ...
///     }
///
/// You can also manually conform to `Identifiable` if you wish, but note that
/// using the object's memory address does *not* work for managed objects.
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol ObjectKeyIdentifiable: Identifiable
{
  /// The stable identity of the entity associated with `self`.
  var id: UInt64 { get }
}

/// :nodoc:
@available(*, deprecated, renamed: "ObjectKeyIdentifiable")
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias ObjectKeyIdentifable = ObjectKeyIdentifiable

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension ObjectKeyIdentifiable where Self: ObjectBase
{
  /// A stable identifier for this object. For managed Realm objects, this
  /// value will be the same for all object instances which refer to the same
  /// object (i.e. for which `Object.isSameObject(as:)` returns true).
  var id: UInt64
  {
    RLMObjectBaseGetCombineId(self)
  }
}

/// :nodoc:
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension ObjectKeyIdentifiable where Self: ProjectionObservable
{
  /// A stable identifier for this projection.
  var id: UInt64
  {
    RLMObjectBaseGetCombineId(rootObject)
  }
}

// MARK: - Combine

/// A type which can be passed to `valuePublisher()` or `changesetPublisher()`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol RealmSubscribable
{
  /// :nodoc:
  func _observe<S>(_ keyPaths: [String]?, on queue: DispatchQueue?, _ subscriber: S)
    -> NotificationToken where S: Subscriber, S.Input == Self
  // :nodoc:
  func _observe<S>(_ keyPaths: [String]?, _ subscriber: S)
    -> NotificationToken where S: Subscriber, S.Input == Void
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher
{
  /// Freezes all Realm objects and collections emitted by the upstream publisher
  ///
  /// Freezing a Realm object makes it no longer live-update when writes are
  /// made to the Realm and makes it safe to pass freely between threads
  /// without using `.threadSafeReference()`.
  ///
  /// ```
  /// // Get a publisher for a Results
  /// let cancellable = myResults.publisher
  ///    // Convert to frozen Results
  ///    .freeze()
  ///    // Unlike live objects, frozen objects can be sent to a concurrent queue
  ///    .receive(on: DispatchQueue.global())
  ///    .sink { frozenResults in
  ///        // Do something with the frozen Results
  ///    }
  /// ```
  ///
  /// - returns: A publisher that publishes frozen copies of the objects which the upstream publisher publishes.
  func freeze<T>() -> Publishers.Map<Self, T> where Output: ThreadConfined, T == Output
  {
    map { $0.freeze() }
  }

  /// Freezes all Realm object changesets emitted by the upstream publisher.
  ///
  /// Freezing a Realm object changeset makes the included object reference
  /// no longer live-update when writes are made to the Realm and makes it
  /// safe to pass freely between threads without using
  /// `.threadSafeReference()`. It also guarantees that the frozen object
  /// contained in the changeset will always match the property changes, which
  /// is not always the case when using thread-safe references.
  ///
  /// ```
  /// // Get a changeset publisher for an object
  /// let cancellable = changesetPublisher(object)
  ///    // Convert to frozen changesets
  ///    .freeze()
  ///    // Unlike live objects, frozen objects can be sent to a concurrent queue
  ///    .receive(on: DispatchQueue.global())
  ///    .sink { changeset in
  ///        // Do something with the frozen changeset
  ///    }
  /// ```
  ///
  /// - returns: A publisher that publishes frozen copies of the changesets
  ///            which the upstream publisher publishes.
  func freeze<T: Object>() -> Publishers.Map<Self, ObjectChange<T>> where Output == ObjectChange<T>
  {
    return map
    {
      if case let .change(object, properties) = $0
      {
        return .change(object.freeze(), properties)
      }
      return $0
    }
  }

  /// Freezes all Realm collection changesets from the upstream publisher.
  ///
  /// Freezing a Realm collection changeset makes the included collection
  /// reference no longer live-update when writes are made to the Realm and
  /// makes it safe to pass freely between threads without using
  /// `.threadSafeReference()`. It also guarantees that the frozen collection
  /// contained in the changeset will always match the change information,
  /// which is not always the case when using thread-safe references.
  ///
  /// ```
  /// // Get a changeset publisher for a collection
  /// let cancellable = myList.changesetPublisher
  ///    // Convert to frozen changesets
  ///    .freeze()
  ///    // Unlike live objects, frozen objects can be sent to a concurrent queue
  ///    .receive(on: DispatchQueue.global())
  ///    .sink { changeset in
  ///        // Do something with the frozen changeset
  ///    }
  /// ```
  ///
  /// - returns: A publisher that publishes frozen copies of the changesets
  ///            which the upstream publisher publishes.
  func freeze<T: RealmCollection>()
    -> Publishers.Map<Self, RealmCollectionChange<T>> where Output == RealmCollectionChange<T>
  {
    map
    {
      switch $0
      {
        case let .initial(collection):
          .initial(collection.freeze())
        case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications):
          .update(collection.freeze(), deletions: deletions, insertions: insertions, modifications: modifications)
        case let .error(error):
          .error(error)
      }
    }
  }

  /// Freezes all Realm sectioned results changesets from the upstream publisher.
  ///
  /// Freezing a Realm sectioned results changeset makes the included  sectioned results
  /// reference no longer live-update when writes are made to the Realm and
  /// makes it safe to pass freely between threads without using
  /// `.threadSafeReference()`. It also guarantees that the frozen sectioned results
  /// contained in the changeset will always match the change information,
  /// which is not always the case when using thread-safe references.
  ///
  /// ```
  /// // Get a changeset publisher for the sectioned results
  /// let cancellable = mySectionedResults.changesetPublisher
  ///    // Convert to frozen changesets
  ///    .freeze()
  ///    // Unlike live objects, frozen objects can be sent to a concurrent queue
  ///    .receive(on: DispatchQueue.global())
  ///    .sink { changeset in
  ///        // Do something with the frozen changeset
  ///    }
  /// ```
  ///
  /// - returns: A publisher that publishes frozen copies of the changesets
  ///            which the upstream publisher publishes.
  func freeze<T: RealmSectionedResult>()
    -> Publishers.Map<Self, SectionedResultsChange<T>> where Output == SectionedResultsChange<T>
  {
    map
    {
      switch $0
      {
        case let .initial(collection):
          .initial(collection.freeze())
        case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications,
                         sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete):
          .update(collection.freeze(), deletions: deletions, insertions: insertions, modifications: modifications,
                  sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete)
      }
    }
  }

  /// Freezes all Realm collection changesets from the upstream publisher.
  ///
  /// Freezing a Realm collection changeset makes the included collection
  /// reference no longer live-update when writes are made to the Realm and
  /// makes it safe to pass freely between threads without using
  /// `.threadSafeReference()`. It also guarantees that the frozen collection
  /// contained in the changeset will always match the change information,
  /// which is not always the case when using thread-safe references.
  ///
  /// ```
  /// // Get a changeset publisher for a collection
  /// let cancellable = myMap.changesetPublisher
  ///    // Convert to frozen changesets
  ///    .freeze()
  ///    // Unlike live objects, frozen objects can be sent to a concurrent queue
  ///    .receive(on: DispatchQueue.global())
  ///    .sink { changeset in
  ///        // Do something with the frozen changeset
  ///    }
  /// ```
  ///
  /// - returns: A publisher that publishes frozen copies of the changesets
  ///            which the upstream publisher publishes.
  func freeze<T: RealmKeyedCollection>()
    -> Publishers.Map<Self, RealmMapChange<T>> where Output == RealmMapChange<T>
  {
    map
    {
      switch $0
      {
        case let .initial(collection):
          .initial(collection.freeze())
        case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications):
          .update(collection.freeze(), deletions: deletions, insertions: insertions, modifications: modifications)
        case let .error(error):
          .error(error)
      }
    }
  }

  /// Freezes all Realm projection changesets emitted by the upstream publisher.
  ///
  /// Freezing a Realm projection changeset makes the included projection reference
  /// no longer live-update when writes are made to the Realm and makes it
  /// safe to pass freely between threads without using
  /// `.threadSafeReference()`. It also guarantees that the frozen projection
  /// contained in the changeset will always match the property changes, which
  /// is not always the case when using thread-safe references.
  ///
  /// ```
  /// // Get a changeset publisher for an projection
  /// let cancellable = changesetPublisher(projection)
  ///    // Convert to frozen changesets
  ///    .freeze()
  ///    // Unlike live projections, frozen projections can be sent to a concurrent queue
  ///    .receive(on: DispatchQueue.global())
  ///    .sink { changeset in
  ///        // Do something with the frozen changeset
  ///    }
  /// ```
  ///
  /// - returns: A publisher that publishes frozen copies of the changesets
  ///            which the upstream publisher publishes.
  func freeze<T: ProjectionObservable>()
    -> Publishers.Map<Self, ObjectChange<T>> where Output == ObjectChange<T>, T: ThreadConfined
  {
    return map
    {
      if case let .change(projection, properties) = $0
      {
        return .change(projection.freeze(), properties)
      }
      return $0
    }
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher where Output: ThreadConfined
{
  /// Enables passing thread-confined objects to a different dispatch queue.
  ///
  /// Each call to `receive(on:)` on a publisher which emits Realm
  /// thread-confined objects must be proceeded by a call to
  /// `.threadSafeReference()`.The returned publisher handles the required
  /// logic to pass the thread-confined object to the new queue. Only serial
  /// dispatch queues are supported and using other schedulers will result in
  /// a fatal error.
  ///
  /// For example, to subscribe on a background thread, do some work there,
  /// then pass the object to the main thread you can do:
  ///
  ///     let cancellable = publisher(myObject)
  ///         .subscribe(on: DispatchQueue(label: "background queue")
  ///         .print()
  ///         .threadSafeReference()
  ///         .receive(on: DispatchQueue.main)
  ///         .sink { object in
  ///             // Do things with the object on the main thread
  ///         }
  ///
  /// Calling this function on a publisher which emits frozen or unmanaged
  /// objects is unneccesary but is allowed.
  ///
  /// - returns: A publisher that supports `receive(on:)` for thread-confined objects.
  func threadSafeReference() -> RealmPublishers.MakeThreadSafe<Self>
  {
    RealmPublishers.MakeThreadSafe(self)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Publisher
{
  /// Enables passing object changesets to a different dispatch queue.
  ///
  /// Each call to `receive(on:)` on a publisher which emits Realm
  /// thread-confined objects must be proceeded by a call to
  /// `.threadSafeReference()`. The returned publisher handles the required
  /// logic to pass the thread-confined object to the new queue. Only serial
  /// dispatch queues are supported and using other schedulers will result in
  /// a fatal error.
  ///
  /// For example, to subscribe on a background thread, do some work there,
  /// then pass the object changeset to the main thread you can do:
  ///
  ///     let cancellable = changesetPublisher(myObject)
  ///         .subscribe(on: DispatchQueue(label: "background queue")
  ///         .print()
  ///         .threadSafeReference()
  ///         .receive(on: DispatchQueue.main)
  ///         .sink { objectChange in
  ///             // Do things with the object on the main thread
  ///         }
  ///
  /// - returns: A publisher that supports `receive(on:)` for thread-confined objects.
  func threadSafeReference<T: Object>()
    -> RealmPublishers.MakeThreadSafeObjectChangeset<Self, T> where Output == ObjectChange<T>
  {
    RealmPublishers.MakeThreadSafeObjectChangeset(self)
  }

  /// Enables passing projection changesets to a different dispatch queue.
  ///
  /// Each call to `receive(on:)` on a publisher which emits Realm
  /// thread-confined projection must be proceeded by a call to
  /// `.threadSafeReference()`. The returned publisher handles the required
  /// logic to pass the thread-confined projection to the new queue. Only serial
  /// dispatch queues are supported and using other schedulers will result in
  /// a fatal error.
  ///
  /// For example, to subscribe on a background thread, do some work there,
  /// then pass the projection changeset to the main thread you can do:
  ///
  ///     let cancellable = changesetPublisher(myProjection)
  ///         .subscribe(on: DispatchQueue(label: "background queue")
  ///         .print()
  ///         .threadSafeReference()
  ///         .receive(on: DispatchQueue.main)
  ///         .sink { projectionChange in
  ///             // Do things with the projection on the main thread
  ///         }
  ///
  /// - returns: A publisher that supports `receive(on:)` for thread-confined objects.
  func threadSafeReference<T: ProjectionObservable>()
    -> RealmPublishers.MakeThreadSafeObjectChangeset<Self, T> where Output == ObjectChange<T>, T: ThreadConfined
  {
    RealmPublishers.MakeThreadSafeObjectChangeset(self)
  }

  /// Enables passing Realm collection changesets to a different dispatch queue.
  ///
  /// Each call to `receive(on:)` on a publisher which emits Realm
  /// thread-confined objects must be proceeded by a call to
  /// `.threadSafeReference()`. The returned publisher handles the required
  /// logic to pass the thread-confined object to the new queue. Only serial
  /// dispatch queues are supported and using other schedulers will result in
  /// a fatal error.
  ///
  /// For example, to subscribe on a background thread, do some work there,
  /// then pass the collection changeset to the main thread you can do:
  ///
  ///     let cancellable = myCollection.changesetPublisher
  ///         .subscribe(on: DispatchQueue(label: "background queue")
  ///         .print()
  ///         .threadSafeReference()
  ///         .receive(on: DispatchQueue.main)
  ///         .sink { collectionChange in
  ///             // Do things with the collection on the main thread
  ///         }
  ///
  /// - returns: A publisher that supports `receive(on:)` for thread-confined objects.
  func threadSafeReference<T: RealmCollection>()
    -> RealmPublishers.MakeThreadSafeCollectionChangeset<Self, T> where Output == RealmCollectionChange<T>
  {
    RealmPublishers.MakeThreadSafeCollectionChangeset(self)
  }

  /// Enables passing Realm collection changesets to a different dispatch queue.
  ///
  /// Each call to `receive(on:)` on a publisher which emits Realm
  /// thread-confined objects must be proceeded by a call to
  /// `.threadSafeReference()`. The returned publisher handles the required
  /// logic to pass the thread-confined object to the new queue. Only serial
  /// dispatch queues are supported and using other schedulers will result in
  /// a fatal error.
  ///
  /// For example, to subscribe on a background thread, do some work there,
  /// then pass the collection changeset to the main thread you can do:
  ///
  ///     let cancellable = myCollection.changesetPublisher
  ///         .subscribe(on: DispatchQueue(label: "background queue")
  ///         .print()
  ///         .threadSafeReference()
  ///         .receive(on: DispatchQueue.main)
  ///         .sink { collectionChange in
  ///             // Do things with the collection on the main thread
  ///         }
  ///
  /// - returns: A publisher that supports `receive(on:)` for thread-confined objects.
  func threadSafeReference<T: RealmKeyedCollection>()
    -> RealmPublishers.MakeThreadSafeKeyedCollectionChangeset<Self, T> where Output == RealmMapChange<T>
  {
    RealmPublishers.MakeThreadSafeKeyedCollectionChangeset(self)
  }

  /// Enables passing Realm sectioned results changesets to a different dispatch queue.
  ///
  /// Each call to `receive(on:)` on a publisher which emits Realm
  /// thread-confined objects must be proceeded by a call to
  /// `.threadSafeReference()`. The returned publisher handles the required
  /// logic to pass the thread-confined object to the new queue. Only serial
  /// dispatch queues are supported and using other schedulers will result in
  /// a fatal error.
  ///
  /// For example, to subscribe on a background thread, do some work there,
  /// then pass the collection changeset to the main thread you can do:
  ///
  ///     let cancellable = mySectionedResults.changesetPublisher
  ///         .subscribe(on: DispatchQueue(label: "background queue")
  ///         .print()
  ///         .threadSafeReference()
  ///         .receive(on: DispatchQueue.main)
  ///         .sink { sectionedResultsChange in
  ///             // Do things with the sectioned results on the main thread
  ///         }
  ///
  /// - returns: A publisher that supports `receive(on:)` for thread-confined objects.
  func threadSafeReference<T: RealmSectionedResult>()
    -> RealmPublishers.MakeThreadSafeSectionedResultsChangeset<Self, T> where Output == SectionedResultsChange<T>
  {
    RealmPublishers.MakeThreadSafeSectionedResultsChangeset(self)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RealmCollection where Self: RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  var objectWillChange: RealmPublishers.WillChange<Self>
  {
    RealmPublishers.WillChange(self)
  }

  /// :nodoc:
  @available(*, deprecated, renamed: "collectionPublisher")
  var publisher: RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self)
  }

  /// A publisher that emits the collection each time the collection changes.
  var collectionPublisher: RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self)
  }

  /// A publisher that emits the collection each time the collection changes on the given property keyPaths.
  func collectionPublisher(keyPaths: [String]?) -> RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self, keyPaths: keyPaths)
  }

  /// A publisher that emits a collection changeset each time the collection changes.
  var changesetPublisher: RealmPublishers.CollectionChangeset<Self>
  {
    RealmPublishers.CollectionChangeset(self)
  }

  /// A publisher that emits a collection changeset each time the collection changes on the given property keyPaths.
  func changesetPublisher(keyPaths: [String]?) -> RealmPublishers.CollectionChangeset<Self>
  {
    RealmPublishers.CollectionChangeset(self, keyPaths: keyPaths)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RealmKeyedCollection where Self: RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  var objectWillChange: RealmPublishers.WillChange<Self>
  {
    RealmPublishers.WillChange(self)
  }

  /// :nodoc:
  @available(*, deprecated, renamed: "collectionPublisher")
  var publisher: RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self)
  }

  /// A publisher that emits the collection each time the collection changes.
  var collectionPublisher: RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self)
  }

  /// A publisher that emits the collection each time the collection changes on the given property keyPaths.
  func collectionPublisher(keyPaths: [String]?) -> RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self, keyPaths: keyPaths)
  }

  /// A publisher that emits a collection changeset each time the collection changes.
  var changesetPublisher: RealmPublishers.MapChangeset<Self>
  {
    RealmPublishers.MapChangeset(self)
  }

  /// A publisher that emits a collection changeset each time the collection changes on the given property keyPaths.
  func changesetPublisher(keyPaths: [String]?) -> RealmPublishers.MapChangeset<Self>
  {
    RealmPublishers.MapChangeset(self, keyPaths: keyPaths)
  }
}

/// Creates a publisher that emits the object each time the object changes.
///
/// - precondition: The object must be a managed object which has not been invalidated.
/// - parameter object: A managed object to observe.
/// - parameter keyPaths: The publisher emits changes on these property keyPaths. If `nil` the publisher emits changes for every property.
/// - returns: A publisher that emits the object each time it changes.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func valuePublisher<T: Object>(_ object: T, keyPaths: [String]? = nil) -> RealmPublishers.Value<T>
{
  RealmPublishers.Value<T>(object, keyPaths: keyPaths)
}

/// Creates a publisher that emits the collection each time the collection changes.
///
/// - precondition: The collection must be a managed collection which has not been invalidated.
/// - parameter object: A managed collection to observe.
/// - parameter keyPaths: The publisher emits changes on these property keyPaths. If `nil` the publisher emits changes for every property.
/// - returns: A publisher that emits the collection each time it changes.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func valuePublisher<T: RealmCollection>(_ collection: T, keyPaths: [String]? = nil) -> RealmPublishers.Value<T>
{
  RealmPublishers.Value<T>(collection, keyPaths: keyPaths)
}

/// Creates a publisher that emits the object each time the object changes.
///
/// - precondition: The object must be a managed object which has not been invalidated.
/// - parameter object: A managed object to observe.
/// - parameter keyPaths: The publisher emits changes on these property keyPaths. If `nil` the publisher emits changes for every property.
/// - returns: A publisher that emits the object each time it changes.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func valuePublisher<T: ProjectionObservable>(_ projection: T, keyPaths: [String]? = nil) -> RealmPublishers.Value<T>
{
  RealmPublishers.Value<T>(projection, keyPaths: keyPaths)
}

/// Creates a publisher that emits an object changeset each time the object changes.
///
/// - precondition: The object must be a managed object which has not been invalidated.
/// - parameter object: A managed object to observe.
/// - parameter keyPaths: The publisher emits changes on these property keyPaths. If `nil` the publisher emits changes for every property.
/// - returns: A publisher that emits an object changeset each time the object changes.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func changesetPublisher<T: Object>(_ object: T, keyPaths: [String]? = nil) -> RealmPublishers.ObjectChangeset<T>
{
  precondition(object.realm != nil, "Only managed objects can be published")
  precondition(!object.isInvalidated, "Object is invalidated or deleted")
  return RealmPublishers.ObjectChangeset<T>
  { queue, fn in
    object.observe(keyPaths: keyPaths, on: queue, fn)
  }
}

/// Creates a publisher that emits an object changeset each time the object changes.
///
/// - precondition: The object must be a projection.
/// - parameter projection: A projection of Realm Object to observe.
/// - parameter keyPaths: The publisher emits changes on these property keyPaths. If `nil` the publisher emits changes for every property.
/// - returns: A publisher that emits an object changeset each time the projection changes.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func changesetPublisher<T: ProjectionObservable>(_ projection: T, keyPaths: [String]? = nil) -> RealmPublishers.ObjectChangeset<T>
{
  precondition(projection.realm != nil, "Only managed objects can be published")
  precondition(!projection.isInvalidated, "Object is invalidated or deleted")
  return RealmPublishers.ObjectChangeset<T>
  { queue, fn in
    projection.observe(keyPaths: keyPaths ?? [], on: queue, fn)
  }
}

/// Creates a publisher that emits a collection changeset each time the collection changes.
///
/// - precondition: The collection must be a managed collection which has not been invalidated.
/// - parameter object: A managed collection to observe.
/// - parameter keyPaths: The publisher emits changes on these property keyPaths. If `nil` the publisher emits changes for every property.
/// - returns: A publisher that emits a collection changeset each time the collection changes.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func changesetPublisher<T: RealmCollection>(_ collection: T, keyPaths: [String]? = nil) -> RealmPublishers.CollectionChangeset<T>
{
  RealmPublishers.CollectionChangeset<T>(collection, keyPaths: keyPaths)
}

// MARK: - Realm

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Realm
{
  /// A publisher that emits Void each time the object changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  var objectWillChange: RealmPublishers.RealmWillChange
  {
    RealmPublishers.RealmWillChange(self)
  }
}

// MARK: - Object

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Object: ObservableObject
{
  /// A publisher that emits Void each time the object changes.
  ///
  /// Despite the name, this actually emits *after* the object has changed.
  public var objectWillChange: RealmPublishers.WillChange<Object>
  {
    RealmPublishers.WillChange(self)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EmbeddedObject: ObservableObject
{
  /// A publisher that emits Void each time the object changes.
  ///
  /// Despite the name, this actually emits *after* the embedded object has changed.
  public var objectWillChange: RealmPublishers.WillChange<EmbeddedObject>
  {
    RealmPublishers.WillChange(self)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ObjectBase: RealmSubscribable
{
  /// :nodoc:
  public func _observe<S: Subscriber>(_ keyPaths: [String]?, on queue: DispatchQueue?, _ subscriber: S) -> NotificationToken where S.Input: ObjectBase
  {
    _observe(keyPaths: keyPaths, on: queue)
    { (object: S.Input?) in
      if let object
      {
        _ = subscriber.receive(object)
      }
      else
      {
        subscriber.receive(completion: .finished)
      }
    }
  }

  /// :nodoc:
  public func _observe<S>(_ keyPaths: [String]?, _ subscriber: S) -> NotificationToken where S: Subscriber, S.Input == Void
  {
    _observe(keyPaths: keyPaths) { _ = subscriber.receive() }
  }
}

// MARK: - List

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension List: ObservableObject, RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<List>
  {
    RealmPublishers.WillChange(self)
  }
}

// MARK: - MutableSet

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MutableSet: ObservableObject, RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<MutableSet>
  {
    RealmPublishers.WillChange(self)
  }
}

// MARK: - Map

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Map: ObservableObject, RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<Map>
  {
    RealmPublishers.WillChange(self)
  }
}

// MARK: - LinkingObjects

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension LinkingObjects: RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<LinkingObjects>
  {
    RealmPublishers.WillChange(self)
  }
}

// MARK: - Results

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Results: RealmSubscribable
{
  /// A publisher that emits Void each time the collection changes.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<Results>
  {
    RealmPublishers.WillChange(self)
  }
}

// MARK: - Sectioned Results

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SectionedResults: RealmSubscribable
{
  /// :nodoc:
  public func _observe<S>(_ keyPaths: [String]? = nil, on queue: DispatchQueue? = nil, _ subscriber: S)
    -> NotificationToken where S: Subscriber, S.Input == Self
  {
    observe(keyPaths: keyPaths, on: queue)
    { change in
      switch change
      {
        case let .initial(collection):
          _ = subscriber.receive(collection)
        case .update(let collection, deletions: _, insertions: _, modifications: _, sectionsToInsert: _, sectionsToDelete: _):
          _ = subscriber.receive(collection)
      }
    }
  }

  /// :nodoc:
  public func _observe<S: Subscriber>(_ keyPaths: [String]? = nil, _ subscriber: S) -> NotificationToken where S.Input == Void
  {
    observe(keyPaths: keyPaths, on: nil) { _ in _ = subscriber.receive() }
  }

  /// A publisher that emits Void each time the sectioned results collection changes.
  ///
  /// Despite the name, this actually emits *after* the sectioned results collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<SectionedResults>
  {
    RealmPublishers.WillChange(self)
  }

  /// A publisher that emits the sectioned results collection each time the sectioned results collection changes.
  public var collectionPublisher: RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self)
  }

  /// A publisher that emits the sectioned results collection each time the sectioned results collection changes on the given property keyPaths.
  public func collectionPublisher(keyPaths: [String]?) -> RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self, keyPaths: keyPaths)
  }

  /// A publisher that emits a sectioned results collection changeset each time the sectioned results collection changes.
  public var changesetPublisher: RealmPublishers.SectionedResultsChangeset<Self>
  {
    RealmPublishers.SectionedResultsChangeset(self)
  }

  /// A publisher that emits a sectioned results collection changeset each time the sectioned results collection changes on the given property keyPaths.
  public func changesetPublisher(keyPaths: [String]?) -> RealmPublishers.SectionedResultsChangeset<Self>
  {
    RealmPublishers.SectionedResultsChangeset(self, keyPaths: keyPaths)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ResultsSection: RealmSubscribable
{
  /// :nodoc:
  public func _observe<S>(_ keyPaths: [String]? = nil, on queue: DispatchQueue? = nil, _ subscriber: S)
    -> NotificationToken where S: Subscriber, S.Input == Self
  {
    observe(keyPaths: keyPaths, on: queue)
    { change in
      switch change
      {
        case let .initial(collection):
          _ = subscriber.receive(collection)
        case .update(let collection, deletions: _, insertions: _, modifications: _, sectionsToInsert: _, sectionsToDelete: _):
          _ = subscriber.receive(collection)
      }
    }
  }

  /// :nodoc:
  public func _observe<S: Subscriber>(_ keyPaths: [String]? = nil, _ subscriber: S) -> NotificationToken where S.Input == Void
  {
    observe(keyPaths: keyPaths, on: nil) { _ in _ = subscriber.receive() }
  }

  /// A publisher that emits Void each time the results section collection changes.
  ///
  /// Despite the name, this actually emits *after* the results section collection has changed.
  public var objectWillChange: RealmPublishers.WillChange<ResultsSection>
  {
    RealmPublishers.WillChange(self)
  }

  /// A publisher that emits the results section collection each time the results section collection changes.
  public var collectionPublisher: RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self)
  }

  /// A publisher that emits the results section collection each time the results section collection changes on the given property keyPaths.
  public func collectionPublisher(keyPaths: [String]?) -> RealmPublishers.Value<Self>
  {
    RealmPublishers.Value(self, keyPaths: keyPaths)
  }

  /// A publisher that emits a results section collection changeset each time the results section collection changes.
  public var changesetPublisher: RealmPublishers.SectionChangeset<Self>
  {
    RealmPublishers.SectionChangeset(self)
  }

  /// A publisher that emits a results section collection changeset each time the results section collection changes on the given property keyPaths.
  public func changesetPublisher(keyPaths: [String]?) -> RealmPublishers.SectionChangeset<Self>
  {
    RealmPublishers.SectionChangeset(self, keyPaths: keyPaths)
  }
}

// MARK: RealmCollection

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RealmCollectionImpl
{
  /// :nodoc:
  func _observe<S>(_ keyPaths: [String]? = nil, on queue: DispatchQueue? = nil, _ subscriber: S)
    -> NotificationToken where S: Subscriber, S.Input == Self
  {
    var col: Self?
    return collection.addNotificationBlock({ collection, _, _ in
      if col == nil, let collection
      {
        col = self.collection === collection ? self : Self(collection: collection)
      }
      if let col
      {
        _ = subscriber.receive(col)
      }
    }, keyPaths: keyPaths, queue: queue)
  }

  /// :nodoc:
  func _observe<S: Subscriber>(_ keyPaths: [String]? = nil, _ subscriber: S) -> NotificationToken where S.Input == Void
  {
    collection.addNotificationBlock({ _, _, _ in _ = subscriber.receive() },
                                    keyPaths: keyPaths, queue: nil)
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AnyRealmCollection: RealmSubscribable {}

// MARK: RealmKeyedCollection

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension RealmKeyedCollection
{
  /// :nodoc:
  func _observe<S>(_ keyPaths: [String]?, on queue: DispatchQueue? = nil, _ subscriber: S)
    -> NotificationToken where S: Subscriber, S.Input == Self
  {
    // FIXME: we could skip some pointless work in converting the changeset to the Swift type here
    observe(keyPaths: keyPaths, on: queue)
    { change in
      switch change
      {
        case let .initial(collection):
          _ = subscriber.receive(collection)
        case .update(let collection, deletions: _, insertions: _, modifications: _):
          _ = subscriber.receive(collection)
        case let .error(error):
          fatalError("Unexpected error \(error)")
      }
    }
  }

  /// :nodoc:
  func _observe<S: Subscriber>(_ subscriber: S) -> NotificationToken where S.Input == Void
  {
    observe(keyPaths: nil, on: nil) { _ in _ = subscriber.receive() }
  }

  /// :nodoc:
  func _observe<S: Subscriber>(_ keyPaths: [String]? = nil, _ subscriber: S) -> NotificationToken where S.Input == Void
  {
    observe(keyPaths: keyPaths, on: nil) { _ in _ = subscriber.receive() }
  }
}

// MARK: Subscriptions

/// A subscription which wraps a Realm notification.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@frozen public struct ObservationSubscription: Subscription
{
  private var token: NotificationToken
  init(token: NotificationToken)
  {
    self.token = token
  }

  /// A unique identifier for identifying publisher streams.
  public var combineIdentifier: CombineIdentifier
  {
    CombineIdentifier(token)
  }

  /// This function is not implemented.
  ///
  /// Realm publishers do not support backpressure and so this function does nothing.
  public func request(_: Subscribers.Demand)
  {}

  /// Stop emitting values on this subscription.
  public func cancel()
  {
    token.invalidate()
  }
}

/// A subscription which wraps a Realm AsyncOpenTask.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@frozen public struct AsyncOpenSubscription: Subscription
{
  private let task: Realm.AsyncOpenTask

  init(task: Realm.AsyncOpenTask)
  {
    self.task = task
  }

  /// A unique identifier for identifying publisher streams.
  public var combineIdentifier: CombineIdentifier
  {
    CombineIdentifier(task.rlmTask)
  }

  /// This function is not implemented.
  ///
  /// Realm publishers do not support backpressure and so this function does nothing.
  public func request(_: Subscribers.Demand)
  {}

  /// Stop emitting values on this subscription.
  public func cancel()
  {
    task.cancel()
  }
}

// MARK: Publishers

/// Combine publishers for Realm types.
///
/// You normally should not create any of these types directly, and should
/// instead use the extension methods which create them.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public enum RealmPublishers
{
  private static func realm(_ config: RLMRealmConfiguration, _ scheduler: some Scheduler) -> Realm?
  {
    try? Realm(RLMRealm(configuration: config, queue: scheduler as? DispatchQueue))
  }

  private static func realm(_ sourceRealm: Realm, _ scheduler: some Scheduler) -> Realm?
  {
    realm(sourceRealm.rlmRealm.configuration, scheduler)
  }

  /// A publisher which emits an asynchronously opened Realm.
  @frozen public struct AsyncOpenPublisher: Publisher
  {
    /// This publisher can fail if there is an error opening the Realm.
    public typealias Failure = Error
    /// This publisher emits an opened Realm.
    public typealias Output = Realm

    private let configuration: Realm.Configuration
    private let callbackQueue: DispatchQueue
    private let onProgressNotificationCallback: ((SyncSession.Progress) -> Void)?

    init(configuration: Realm.Configuration,
         callbackQueue: DispatchQueue = .main,
         onProgressNotificationCallback: ((SyncSession.Progress) -> Void)? = nil)
    {
      self.configuration = configuration
      self.callbackQueue = callbackQueue
      self.onProgressNotificationCallback = onProgressNotificationCallback
    }

    /// Triggers an event when there is a notification on the async open progress.
    ///
    /// This should be called directly after invoking the publisher.
    ///
    /// - Parameter onProgressNotificationCallback: Callback which will be invoked when there is an update on progress.
    /// - Returns: A publisher that emits an asynchronously opened Realm.
    public func onProgressNotification(_ onProgressNotificationCallback: @escaping ((SyncSession.Progress) -> Void)) -> Self
    {
      Self(configuration: configuration,
           callbackQueue: callbackQueue,
           onProgressNotificationCallback: onProgressNotificationCallback)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      let rlmTask = RLMRealm.asyncOpen(with: configuration.rlmConfiguration,
                                       callbackQueue: callbackQueue)
      { rlmRealm, error in
        if let realm = rlmRealm.flatMap(Realm.init)
        {
          _ = subscriber.receive(realm)
          subscriber.receive(completion: .finished)
        }
        else
        {
          subscriber.receive(completion: .failure(error ?? Realm.Error.callFailed))
        }
      }
      let task = Realm.AsyncOpenTask(rlmTask: rlmTask)
      if let onProgressNotificationCallback
      {
        task.addProgressNotification(queue: callbackQueue, block: onProgressNotificationCallback)
      }
      subscriber.receive(subscription: AsyncOpenSubscription(task: task))
    }

    /// Specifies the scheduler on which to perform the async open task.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive(on scheduler: some Scheduler) -> Self
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }

      return Self(configuration: configuration,
                  callbackQueue: queue,
                  onProgressNotificationCallback: onProgressNotificationCallback)
    }
  }

  /// A publisher which emits Void each time the Realm is refreshed.
  ///
  /// Despite the name, this actually emits *after* the Realm is refreshed.
  @frozen public struct RealmWillChange: Publisher
  {
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits Void.
    public typealias Output = Void

    private let realm: Realm

    init(_ realm: Realm)
    {
      self.realm = realm
    }

    /// Captures the `NotificationToken` produced by observing a Realm Collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `RealmWillChangeWithToken` Publisher.
    public func saveToken<T>(on object: T, for keyPath: WritableKeyPath<T, NotificationToken?>) -> RealmWillChangeWithToken<T>
    {
      RealmWillChangeWithToken<T>(realm, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = realm.observe
      { _, _ in
        _ = subscriber.receive()
      }
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }
  }

  /// :nodoc:
  public class RealmWillChangeWithToken<T>: Publisher
  {
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits Void.
    public typealias Output = Void

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private let realm: Realm
    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    init(_ realm: Realm,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      self.realm = realm
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = realm.observe
      { _, _ in
        _ = subscriber.receive()
      }
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }
  }

  /// A publisher which emits Void each time the object is mutated.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  @frozen public struct WillChange<Collection: RealmSubscribable>: Publisher where Collection: ThreadConfined
  {
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits Void.
    public typealias Output = Void

    private let collection: Collection

    init(_ collection: Collection)
    {
      self.collection = collection
    }

    /// Captures the `NotificationToken` produced by observing a Realm Collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `WillChangeWithToken` Publisher.
    public func saveToken<T>(on object: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> WillChangeWithToken<Collection, T>
    {
      WillChangeWithToken<Collection, T>(collection, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection._observe(nil, subscriber)
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }
  }

  /// A publisher which emits Void each time the object is mutated.
  ///
  /// Despite the name, this actually emits *after* the collection has changed.
  public class WillChangeWithToken<Collection: RealmSubscribable, T>: Publisher where Collection: ThreadConfined
  {
    /// This publisher cannot fail.
    public typealias Failure = Never
    /// This publisher emits Void.
    public typealias Output = Void

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private let object: Collection
    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    init(_ object: Collection,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      self.object = object
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = object._observe(nil, subscriber)
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }
  }

  /// A publisher which emits an object or collection each time that object is mutated.
  @frozen public struct Value<Subscribable: RealmSubscribable>: Publisher where Subscribable: ThreadConfined
  {
    /// This publisher cannot actually fail and will change to Never in the future.
    public typealias Failure = Error
    /// This publisher emits the object or collection which it is publishing.
    public typealias Output = Subscribable

    private let subscribable: Subscribable
    private let keyPaths: [String]?
    private let queue: DispatchQueue?
    init(_ subscribable: Subscribable, keyPaths: [String]? = nil, queue: DispatchQueue? = nil)
    {
      precondition(subscribable.realm != nil, "Only managed objects can be published")
      self.subscribable = subscribable
      self.keyPaths = keyPaths
      self.queue = queue
    }

    /// Captures the `NotificationToken` produced by observing a Realm Collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `ValueWithToken` Publisher.
    public func saveToken<T>(on object: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> ValueWithToken<Subscribable, T>
    {
      ValueWithToken<Subscribable, T>(subscribable, queue, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      subscriber.receive(subscription: ObservationSubscription(token: subscribable._observe(keyPaths, on: queue, subscriber)))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> Value<Subscribable>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return Value(subscribable, keyPaths: keyPaths, queue: queue)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> RealmPublishers.Handover<Self, S>
    {
      Handover(self, scheduler, subscribable.realm!)
    }
  }

  /// A publisher which emits an object or collection each time that object is mutated.
  public class ValueWithToken<Subscribable: RealmSubscribable, T>: Publisher where Subscribable: ThreadConfined
  {
    /// This publisher cannot actually fail and will change to Never in the future.
    public typealias Failure = Error
    /// This publisher emits the object or collection which it is publishing.
    public typealias Output = Subscribable

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private let object: Subscribable
    private let queue: DispatchQueue?

    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    init(_ object: Subscribable,
         _ queue: DispatchQueue? = nil,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      precondition(object.realm != nil, "Only managed objects can be published")
      self.object = object
      self.queue = queue
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      let token = object._observe(nil, on: queue, subscriber)
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> ValueWithToken<Subscribable, T>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return ValueWithToken(object, queue, tokenParent, tokenKeyPath)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> Handover<ValueWithToken, S>
    {
      Handover(self, scheduler, object.realm!)
    }
  }

  /// A helper publisher used to support `receive(on:)` on Realm publishers.
  @frozen public struct Handover<Upstream: Publisher, S: Scheduler>: Publisher where Upstream.Output: ThreadConfined
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let config: RLMRealmConfiguration
    private let upstream: Upstream
    private let scheduler: S

    init(_ upstream: Upstream, _ scheduler: S, _ realm: Realm)
    {
      config = realm.rlmRealm.configuration
      self.upstream = upstream
      self.scheduler = scheduler
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      let config = config
      upstream
        .map { ThreadSafeReference(to: $0) }
        .receive(on: scheduler)
        .compactMap { realm(config, scheduler)?.resolve($0) }
        .receive(subscriber: subscriber)
    }
  }

  /// A publisher which makes `receive(on:)` work for streams of thread-confined objects
  ///
  /// Create using .threadSafeReference()
  @frozen public struct MakeThreadSafe<Upstream: Publisher>: Publisher where Upstream.Output: ThreadConfined
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    init(_ upstream: Upstream)
    {
      self.upstream = upstream
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      upstream.receive(subscriber: subscriber)
    }

    /// Specifies the scheduler on which to receive elements from the publisher.
    ///
    /// This publisher converts each value emitted by the upstream
    /// publisher to a `ThreadSafeReference`, passes it to the target
    /// scheduler, and then converts back to the original type.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandover<Upstream, S>
    {
      DeferredHandover(upstream, scheduler)
    }
  }

  /// A publisher which delivers thread-confined values to a serial dispatch queue.
  ///
  /// Create using `.threadSafeReference().receive(on: queue)` on a publisher
  /// that emits thread-confined objects.
  @frozen public struct DeferredHandover<Upstream: Publisher, S: Scheduler>: Publisher where Upstream.Output: ThreadConfined
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    private let scheduler: S
    init(_ upstream: Upstream, _ scheduler: S)
    {
      self.upstream = upstream
      self.scheduler = scheduler
    }

    private enum Handover
    {
      case object(_ object: Output)
      case tsr(_ tsr: ThreadSafeReference<Output>, config: RLMRealmConfiguration)
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      upstream
        .map
        { (obj: Output) -> Handover in
          guard let realm = obj.realm, !realm.isFrozen else { return .object(obj) }
          return .tsr(ThreadSafeReference(to: obj), config: realm.rlmRealm.configuration)
        }
        .receive(on: scheduler)
        .compactMap
        { (handover: Handover) -> Output? in
          switch handover
          {
            case let .object(obj):
              obj
            case let .tsr(tsr, config):
              realm(config, scheduler)?.resolve(tsr)
          }
        }
        .receive(subscriber: subscriber)
    }
  }

  /// A publisher which emits ObjectChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `objectChangeset()` function.
  @frozen public struct ObjectChangeset<O: ThreadConfined>: Publisher
  {
    /// This publisher emits a ObjectChange<T> indicating which object and
    /// which properties of that object have changed each time a Realm is
    /// refreshed after a write transaction which modifies the observed
    /// object.
    public typealias Output = ObjectChange<O>
    /// This publisher reports error via the `.error` case of ObjectChange.
    public typealias Failure = Never

    @usableFromInline
    typealias Observe = (_ queue: DispatchQueue?, @escaping (Output) -> Void) -> NotificationToken
    private let observe: Observe
    private let queue: DispatchQueue?
    init(_ observe: @escaping Observe, queue: DispatchQueue? = nil)
    {
      self.observe = observe
      self.queue = queue
    }

    /// Captures the `NotificationToken` produced by observing a Realm Collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `ObjectChangesetWithToken` Publisher.
    public func saveToken<T>(on tokenParent: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> ObjectChangesetWithToken<O, T>
    {
      ObjectChangesetWithToken<O, T>(observe, queue, tokenParent, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = observe(queue)
      { change in
        switch change
        {
          case let .change(o, properties):
            _ = subscriber.receive(.change(o, properties))
          case let .error(error):
            _ = subscriber.receive(.error(error))
          case .deleted:
            subscriber.receive(completion: .finished)
        }
      }
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> ObjectChangeset<O>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return ObjectChangeset(observe, queue: queue)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverObjectChangeset<Self, O, S>
    {
      DeferredHandoverObjectChangeset(self, scheduler)
    }
  }

  /// A publisher which emits ObjectChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `objectChangeset()` function.
  public class ObjectChangesetWithToken<O: Object, T>: Publisher
  {
    /// This publisher emits a ObjectChange<T> indicating which object and
    /// which properties of that object have changed each time a Realm is
    /// refreshed after a write transaction which modifies the observed
    /// object.
    public typealias Output = ObjectChange<O>
    /// This publisher reports error via the `.error` case of ObjectChange.
    public typealias Failure = Never

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    @usableFromInline
    typealias Observe = (_ queue: DispatchQueue?, @escaping (Output) -> Void) -> NotificationToken
    private let observe: Observe
    private let queue: DispatchQueue?
    init(_ observe: @escaping Observe,
         _ queue: DispatchQueue? = nil,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      self.observe = observe
      self.queue = queue
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = observe(queue)
      { change in
        switch change
        {
          case let .change(o, properties):
            _ = subscriber.receive(.change(o, properties))
          case let .error(error):
            _ = subscriber.receive(.error(error))
          case .deleted:
            subscriber.receive(completion: .finished)
        }
      }
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> ObjectChangesetWithToken<O, T>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return ObjectChangesetWithToken(observe, queue, tokenParent, tokenKeyPath)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverObjectChangeset<ObjectChangesetWithToken, T, S>
    {
      DeferredHandoverObjectChangeset(self, scheduler)
    }
  }

  /// A helper publisher created by calling `.threadSafeReference()` on a publisher which emits thread-confined values.
  @frozen public struct MakeThreadSafeObjectChangeset<Upstream: Publisher, T: ThreadConfined>: Publisher where Upstream.Output == ObjectChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    init(_ upstream: Upstream)
    {
      self.upstream = upstream
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      upstream.receive(subscriber: subscriber)
    }

    /// Specifies the scheduler to deliver object changesets to.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverObjectChangeset<Upstream, T, S>
    {
      DeferredHandoverObjectChangeset(upstream, scheduler)
    }
  }

  /// A publisher which delivers thread-confined object changesets to a serial dispatch queue.
  ///
  /// Create using `.threadSafeReference().receive(on: queue)` on a publisher
  /// that emits `ObjectChange`.
  @frozen public struct DeferredHandoverObjectChangeset<Upstream: Publisher, T: ThreadConfined, S: Scheduler>: Publisher where Upstream.Output == ObjectChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    private let scheduler: S

    init(_ upstream: Upstream, _ scheduler: S)
    {
      self.upstream = upstream
      self.scheduler = scheduler
    }

    private enum Handover
    {
      /// .error and .change containing a frozen object can be delivered
      /// without any handover
      case passthrough(_ change: ObjectChange<T>)
      /// .change containing a live object need to be wrapped in a TSR.
      /// We also hold a reference to a pinned Realm to ensure that the
      /// source version remains pinned and we can deliver the object at
      /// the same version as the change information.
      case tsr(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>,
               _ properties: [PropertyChange])
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      upstream
        .map
        { (change: Output) -> Handover in
          guard case let .change(obj, properties) = change else { return .passthrough(change) }
          guard let realm = obj.realm, !realm.isFrozen else { return .passthrough(change) }
          return .tsr(RLMPinnedRealm(realm: realm.rlmRealm),
                      ThreadSafeReference(to: obj), properties)
        }
        .receive(on: scheduler)
        .compactMap
        { (handover: Handover) -> Output? in
          switch handover
          {
            case let .passthrough(change):
              return change
            case let .tsr(pin, tsr, properties):
              defer { pin.unpin() }
              if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
              {
                return .change(resolved, properties)
              }
              return nil
          }
        }
        .receive(subscriber: subscriber)
    }
  }

  /// A publisher which emits RealmCollectionChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmCollection.
  @frozen public struct CollectionChangeset<Collection: RealmCollection>: Publisher
  {
    public typealias Output = RealmCollectionChange<Collection>
    /// This publisher reports error via the `.error` case of RealmCollectionChange.
    public typealias Failure = Never

    private let collection: Collection
    private let keyPaths: [String]?
    private let queue: DispatchQueue?
    init(_ collection: Collection, keyPaths: [String]? = nil, queue: DispatchQueue? = nil)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.keyPaths = keyPaths
      self.queue = queue
    }

    /// Captures the `NotificationToken` produced by observing a Realm Collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `CollectionChangesetWithToken` Publisher.
    public func saveToken<T>(on object: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> CollectionChangesetWithToken<Collection, T>
    {
      CollectionChangesetWithToken<Collection, T>(collection, queue, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(keyPaths: keyPaths, on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> CollectionChangeset<Collection>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return CollectionChangeset(collection, keyPaths: keyPaths, queue: queue)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverCollectionChangeset<Self, Collection, S>
    {
      DeferredHandoverCollectionChangeset(self, scheduler)
    }
  }

  /// A publisher which emits RealmMapChange<Key, Value> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmCollection.
  @frozen public struct MapChangeset<Collection: RealmKeyedCollection>: Publisher
  {
    public typealias Output = RealmMapChange<Collection>
    /// This publisher reports error via the `.error` case of RealmMapChange.
    public typealias Failure = Never

    private let collection: Collection
    private let keyPaths: [String]?
    private let queue: DispatchQueue?
    init(_ collection: Collection, keyPaths: [String]? = nil, queue: DispatchQueue? = nil)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.keyPaths = keyPaths
      self.queue = queue
    }

    /// Captures the `NotificationToken` produced by observing a Realm Collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `CollectionChangesetWithToken` Publisher.
    public func saveToken<T>(on object: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> MapChangesetWithToken<Collection, T>
    {
      MapChangesetWithToken<Collection, T>(collection, queue, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(keyPaths: keyPaths, on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> MapChangeset<Collection>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return MapChangeset(collection, keyPaths: keyPaths, queue: queue)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverKeyedCollectionChangeset<Self, Collection, S>
    {
      DeferredHandoverKeyedCollectionChangeset(self, scheduler)
    }
  }

  /// A publisher which emits SectionedResultsChange<Collection> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmSectionedResult.
  @frozen public struct SectionedResultsChangeset<Collection: RealmSectionedResult>: Publisher
  {
    public typealias Output = SectionedResultsChange<Collection>
    /// This publisher reports error via the `.error` case of SectionedResultsChange.
    public typealias Failure = Never

    private let collection: Collection
    private let keyPaths: [String]?
    private let queue: DispatchQueue?
    init(_ collection: Collection, keyPaths: [String]? = nil, queue: DispatchQueue? = nil)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.keyPaths = keyPaths
      self.queue = queue
    }

    /// Captures the `NotificationToken` produced by observing the collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `SectionedResultsChangesetWithToken` Publisher.
    public func saveToken<T>(on object: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> SectionedResultsChangesetWithToken<Collection, T>
    {
      SectionedResultsChangesetWithToken<Collection, T>(collection, queue, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(keyPaths: keyPaths, on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> SectionedResultsChangeset<Collection>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return SectionedResultsChangeset(collection, keyPaths: keyPaths, queue: queue)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverSectionedResultsChangeset<Self, Collection, S>
    {
      DeferredHandoverSectionedResultsChangeset(self, scheduler)
    }
  }

  /// A publisher which emits SectionedResultsChange<Collection> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmSectionedResult.
  @frozen public struct SectionChangeset<Collection: RealmSectionedResult>: Publisher
  {
    public typealias Output = SectionedResultsChange<Collection>
    /// This publisher reports error via the `.error` case of SectionedResultsChange.
    public typealias Failure = Never

    private let collection: Collection
    private let keyPaths: [String]?
    private let queue: DispatchQueue?
    init(_ collection: Collection, keyPaths: [String]? = nil, queue: DispatchQueue? = nil)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.keyPaths = keyPaths
      self.queue = queue
    }

    /// Captures the `NotificationToken` produced by observing a the collection.
    ///
    /// This allows you to do notification skipping when performing a `Realm.write(withoutNotifying:)`. You should use this call if you
    /// require to write to the Realm database and ignore this specific observation chain.
    /// The `NotificationToken` will be saved on the specified `KeyPath`from the observation block set up in `receive(subscriber:)`.
    ///
    /// - Parameters:
    ///   - object: The object which the `NotificationToken` is written to.
    ///   - keyPath: The KeyPath which the `NotificationToken` is written to.
    /// - Returns: A `SectionedResultsChangesetWithToken` Publisher.
    public func saveToken<T>(on object: T, at keyPath: WritableKeyPath<T, NotificationToken?>) -> SectionedResultsChangesetWithToken<Collection, T>
    {
      SectionedResultsChangesetWithToken<Collection, T>(collection, queue, object, keyPath)
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(keyPaths: keyPaths, on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> SectionedResultsChangeset<Collection>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return SectionedResultsChangeset(collection, keyPaths: keyPaths, queue: queue)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverSectionedResultsChangeset<Self, Collection, S>
    {
      DeferredHandoverSectionedResultsChangeset(self, scheduler)
    }
  }

  /// A publisher which emits RealmCollectionChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmCollection.
  public class CollectionChangesetWithToken<Collection: RealmCollection, T>: Publisher
  {
    public typealias Output = RealmCollectionChange<Collection>
    /// This publisher reports error via the `.error` case of RealmCollectionChange.
    public typealias Failure = Never

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    private let collection: Collection
    private let queue: DispatchQueue?
    init(_ collection: Collection,
         _ queue: DispatchQueue? = nil,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.queue = queue
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> CollectionChangesetWithToken<Collection, T>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return CollectionChangesetWithToken(collection, queue, tokenParent, tokenKeyPath)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverCollectionChangeset<CollectionChangesetWithToken, Collection, S>
    {
      DeferredHandoverCollectionChangeset(self, scheduler)
    }
  }

  /// A publisher which emits SectionedResultsChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmSectionedResult.
  public class SectionedResultsChangesetWithToken<Collection: RealmSectionedResult, T>: Publisher
  {
    public typealias Output = SectionedResultsChange<Collection>
    /// This publisher reports error via the `.error` case of RealmCollectionChange.
    public typealias Failure = Never

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    private let collection: Collection
    private let queue: DispatchQueue?
    init(_ collection: Collection,
         _ queue: DispatchQueue? = nil,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.queue = queue
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> SectionedResultsChangesetWithToken<Collection, T>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return SectionedResultsChangesetWithToken(collection, queue, tokenParent, tokenKeyPath)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverSectionedResultsChangeset<SectionedResultsChangesetWithToken, Collection, S>
    {
      DeferredHandoverSectionedResultsChangeset(self, scheduler)
    }
  }

  /// A publisher which emits SectionedResultsChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmSectionedResult.
  public class SectionChangesetWithToken<Collection: RealmSectionedResult, T>: Publisher
  {
    public typealias Output = SectionedResultsChange<Collection>
    /// This publisher reports error via the `.error` case of RealmCollectionChange.
    public typealias Failure = Never

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    private let collection: Collection
    private let queue: DispatchQueue?
    init(_ collection: Collection,
         _ queue: DispatchQueue? = nil,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.queue = queue
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> SectionedResultsChangesetWithToken<Collection, T>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return SectionedResultsChangesetWithToken(collection, queue, tokenParent, tokenKeyPath)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverSectionChangeset<SectionChangesetWithToken, Collection, S>
    {
      DeferredHandoverSectionChangeset(self, scheduler)
    }
  }

  /// A publisher which emits RealmMapChange<T> each time the observed object is modified
  ///
  /// `receive(on:)` and `subscribe(on:)` can be called directly on this
  /// publisher, and calling `.threadSafeReference()` is only required if
  /// there is an intermediate transform. If `subscribe(on:)` is used, it
  /// should always be the first operation in the pipeline.
  ///
  /// Create this publisher using the `changesetPublisher` property on RealmCollection.
  public class MapChangesetWithToken<Collection: RealmKeyedCollection, T>: Publisher
  {
    public typealias Output = RealmMapChange<Collection>
    /// This publisher reports error via the `.error` case of RealmCollectionChange.
    public typealias Failure = Never

    typealias TokenParent = T
    typealias TokenKeyPath = WritableKeyPath<T, NotificationToken?>

    private var tokenParent: TokenParent
    private var tokenKeyPath: TokenKeyPath

    private let collection: Collection
    private let queue: DispatchQueue?
    init(_ collection: Collection,
         _ queue: DispatchQueue? = nil,
         _ tokenParent: TokenParent,
         _ tokenKeyPath: TokenKeyPath)
    {
      precondition(collection.realm != nil, "Only managed collections can be published")
      self.collection = collection
      self.queue = queue
      self.tokenParent = tokenParent
      self.tokenKeyPath = tokenKeyPath
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input
    {
      let token = collection.observe(on: queue)
      { change in
        _ = subscriber.receive(change)
      }
      tokenParent[keyPath: tokenKeyPath] = token
      subscriber.receive(subscription: ObservationSubscription(token: token))
    }

    /// Specifies the scheduler on which to perform subscribe, cancel, and request operations.
    ///
    /// For Realm Publishers, this determines which queue the underlying
    /// change notifications are sent to. If `receive(on:)` is not used
    /// subsequently, it also will determine which queue elements received
    /// from the publisher are evaluated on. Currently only serial dispatch
    /// queues are supported, and the `options:` parameter is not
    /// supported.
    ///
    /// - parameter scheduler: The serial dispatch queue to perform the subscription on.
    /// - returns: A publisher which subscribes on the given scheduler.
    public func subscribe(on scheduler: some Scheduler) -> MapChangesetWithToken<Collection, T>
    {
      guard let queue = scheduler as? DispatchQueue
      else
      {
        fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
      }
      return MapChangesetWithToken(collection, queue, tokenParent, tokenKeyPath)
    }

    /// Specifies the scheduler on which to perform downstream operations.
    ///
    /// This differs from `subscribe(on:)` in how it is integrated with the
    /// autorefresh cycle. When using `subscribe(on:)`, the subscription is
    /// performed on the target scheduler and the publisher will emit the
    /// collection during the refresh. When using `receive(on:)`, the
    /// collection is then converted to a `ThreadSafeReference` and
    /// delivered to the target scheduler with no integration into the
    /// autorefresh cycle, meaning it may arrive some time after the
    /// refresh occurs.
    ///
    /// When in doubt, you probably want `subscribe(on:)`
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverKeyedCollectionChangeset<MapChangesetWithToken, Collection, S>
    {
      DeferredHandoverKeyedCollectionChangeset(self, scheduler)
    }
  }

  /// A helper publisher created by calling `.threadSafeReference()` on a
  /// publisher which emits `RealmCollectionChange`.
  @frozen public struct MakeThreadSafeCollectionChangeset<Upstream: Publisher, T: RealmCollection>: Publisher where Upstream.Output == RealmCollectionChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    init(_ upstream: Upstream)
    {
      self.upstream = upstream
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      upstream.receive(subscriber: subscriber)
    }

    /// Specifies the scheduler on which to receive elements from the publisher.
    ///
    /// This publisher converts each value emitted by the upstream
    /// publisher to a `ThreadSafeReference`, passes it to the target
    /// scheduler, and then converts back to the original type.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverCollectionChangeset<Upstream, T, S>
    {
      DeferredHandoverCollectionChangeset(upstream, scheduler)
    }
  }

  /// A helper publisher created by calling `.threadSafeReference()` on a
  /// publisher which emits `RealmMapChange`.
  @frozen public struct MakeThreadSafeKeyedCollectionChangeset<Upstream: Publisher, T: RealmKeyedCollection>: Publisher where Upstream.Output == RealmMapChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    init(_ upstream: Upstream)
    {
      self.upstream = upstream
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      upstream.receive(subscriber: subscriber)
    }

    /// Specifies the scheduler on which to receive elements from the publisher.
    ///
    /// This publisher converts each value emitted by the upstream
    /// publisher to a `ThreadSafeReference`, passes it to the target
    /// scheduler, and then converts back to the original type.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverKeyedCollectionChangeset<Upstream, T, S>
    {
      DeferredHandoverKeyedCollectionChangeset(upstream, scheduler)
    }
  }

  /// A helper publisher created by calling `.threadSafeReference()` on a
  /// publisher which emits `SectionedResultsChange`.
  @frozen public struct MakeThreadSafeSectionedResultsChangeset<Upstream: Publisher, T: RealmSectionedResult>: Publisher where Upstream.Output == SectionedResultsChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    init(_ upstream: Upstream)
    {
      self.upstream = upstream
    }

    /// :nodoc:
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input
    {
      upstream.receive(subscriber: subscriber)
    }

    /// Specifies the scheduler on which to receive elements from the publisher.
    ///
    /// This publisher converts each value emitted by the upstream
    /// publisher to a `ThreadSafeReference`, passes it to the target
    /// scheduler, and then converts back to the original type.
    ///
    /// - parameter scheduler: The serial dispatch queue to receive values on.
    /// - returns: A publisher which delivers values to the given scheduler.
    public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverSectionedResultsChangeset<Upstream, T, S>
    {
      DeferredHandoverSectionedResultsChangeset(upstream, scheduler)
    }
  }

  /// A publisher which delivers thread-confined collection changesets to a
  /// serial dispatch queue.
  ///
  /// Create using `.threadSafeReference().receive(on: queue)` on a publisher
  /// that emits `RealmCollectionChange`.
  @frozen public struct DeferredHandoverCollectionChangeset<Upstream: Publisher, T: RealmCollection, S: Scheduler>: Publisher where Upstream.Output == RealmCollectionChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    private let scheduler: S
    init(_ upstream: Upstream, _ scheduler: S)
    {
      self.upstream = upstream
      self.scheduler = scheduler
    }

    private enum Handover
    {
      /// A collection change which does not contain a live object and so
      /// can be delivered directly
      case passthrough(_ change: RealmCollectionChange<T>)
      /// The initial and update notifications for live collections need
      /// to wrap the collection in a thread-safe reference and hold onto
      /// a pinned Realm to ensure that the version which the change
      /// information is for stays pinned until it's delivered.
      case initial(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>)
      case update(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>, deletions: [Int],
                  insertions: [Int], modifications: [Int])
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      upstream
        .map
        { (change: Output) -> Handover in
          switch change
          {
            case let .initial(collection):
              guard let realm = collection.realm, !realm.isFrozen else { return .passthrough(change) }
              return .initial(RLMPinnedRealm(realm: realm.rlmRealm),
                              ThreadSafeReference(to: collection))
            case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications):
              guard let realm = collection.realm, !realm.isFrozen else { return .passthrough(change) }
              return .update(RLMPinnedRealm(realm: realm.rlmRealm),
                             ThreadSafeReference(to: collection),
                             deletions: deletions, insertions: insertions,
                             modifications: modifications)
            case .error:
              return .passthrough(change)
          }
        }
        .receive(on: scheduler)
        .compactMap
        { (handover: Handover) -> Output? in
          switch handover
          {
            case let .passthrough(change):
              return change
            case let .initial(pin, tsr):
              defer { pin.unpin() }
              if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
              {
                return .initial(resolved)
              }
              return nil
            case let .update(pin, tsr, deletions: deletions, insertions: insertions, modifications: modifications):
              defer { pin.unpin() }
              if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
              {
                return .update(resolved, deletions: deletions, insertions: insertions, modifications: modifications)
              }
              return nil
          }
        }
        .receive(subscriber: subscriber)
    }
  }

  /// A publisher which delivers thread-confined `Map` changesets to a
  /// serial dispatch queue.
  ///
  /// Create using `.threadSafeReference().receive(on: queue)` on a publisher
  /// that emits `RealmMapChange`.
  @frozen public struct DeferredHandoverKeyedCollectionChangeset<Upstream: Publisher, T: RealmKeyedCollection, S: Scheduler>: Publisher where Upstream.Output == RealmMapChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    private let scheduler: S
    init(_ upstream: Upstream, _ scheduler: S)
    {
      self.upstream = upstream
      self.scheduler = scheduler
    }

    private enum Handover
    {
      /// A collection change which does not contain a live object and so
      /// can be delivered directly
      case passthrough(_ change: RealmMapChange<T>)
      /// The initial and update notifications for live collections need
      /// to wrap the collection in a thread-safe reference and hold onto
      /// a pinned Realm to ensure that the version which the change
      /// information is for stays pinned until it's delivered.
      case initial(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>)
      case update(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>,
                  deletions: [T.Key], insertions: [T.Key], modifications: [T.Key])
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      upstream
        .map
        { (change: Output) -> Handover in
          switch change
          {
            case let .initial(collection):
              guard let realm = collection.realm, !realm.isFrozen else { return .passthrough(change) }
              return .initial(RLMPinnedRealm(realm: realm.rlmRealm),
                              ThreadSafeReference(to: collection))
            case let .update(collection, deletions: deletions, insertions: insertions, modifications: modifications):
              guard let realm = collection.realm, !realm.isFrozen else { return .passthrough(change) }
              return .update(RLMPinnedRealm(realm: realm.rlmRealm),
                             ThreadSafeReference(to: collection),
                             deletions: deletions, insertions: insertions, modifications: modifications)
            case .error:
              return .passthrough(change)
          }
        }
        .receive(on: scheduler)
        .compactMap
        { (handover: Handover) -> Output? in
          switch handover
          {
            case let .passthrough(change):
              return change
            case let .initial(pin, tsr):
              defer { pin.unpin() }
              if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
              {
                return .initial(resolved)
              }
              return nil
            case let .update(pin, tsr, deletions: deletions,
                             insertions: insertions, modifications: modifications):
              defer { pin.unpin() }
              if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
              {
                return .update(resolved, deletions: deletions, insertions: insertions,
                               modifications: modifications)
              }
              return nil
          }
        }
        .receive(subscriber: subscriber)
    }
  }

  private enum SectionedHandover<T: RealmSectionedResult, S: Scheduler>
  {
    /// A collection change which does not contain a live object and so
    /// can be delivered directly
    case passthrough(_ change: SectionedResultsChange<T>)
    /// The initial and update notifications for live collections need
    /// to wrap the collection in a thread-safe reference and hold onto
    /// a pinned Realm to ensure that the version which the change
    /// information is for stays pinned until it's delivered.
    case initial(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>)
    case update(_ pin: RLMPinnedRealm, _ tsr: ThreadSafeReference<T>,
                deletions: [IndexPath], insertions: [IndexPath], modifications: [IndexPath],
                sectionsToInsert: IndexSet, sectionsToDelete: IndexSet)

    init(_ change: SectionedResultsChange<T>)
    {
      switch change
      {
        case let .initial(collection):
          guard let realm = collection.realm, !realm.isFrozen
          else
          {
            self = .passthrough(change)
            return
          }
          self = .initial(RLMPinnedRealm(realm: realm.rlmRealm),
                          ThreadSafeReference(to: collection))
        case let .update(collection, deletions: deletions, insertions: insertions,
                         modifications: modifications,
                         sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete):
          guard let realm = collection.realm, !realm.isFrozen
          else
          {
            self = .passthrough(change)
            return
          }
          self = .update(RLMPinnedRealm(realm: realm.rlmRealm),
                         ThreadSafeReference(to: collection),
                         deletions: deletions, insertions: insertions, modifications: modifications,
                         sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete)
      }
    }

    func resolve(_ scheduler: S) -> SectionedResultsChange<T>?
    {
      switch self
      {
        case let .passthrough(change):
          return change
        case let .initial(pin, tsr):
          defer { pin.unpin() }
          if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
          {
            return .initial(resolved)
          }
          return nil
        case let .update(pin, tsr, deletions: deletions, insertions: insertions, modifications: modifications,
                         sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete):
          defer { pin.unpin() }
          if let resolved = realm(pin.configuration, scheduler)?.resolve(tsr)
          {
            return .update(resolved, deletions: deletions, insertions: insertions, modifications: modifications,
                           sectionsToInsert: sectionsToInsert, sectionsToDelete: sectionsToDelete)
          }
          return nil
      }
    }
  }

  // swiftlint:disable type_name
  /// A publisher which delivers thread-confined collection changesets to a
  /// serial dispatch queue.
  ///
  /// Create using `.threadSafeReference().receive(on: queue)` on a publisher
  /// that emits `RealmCollectionChange`.
  @frozen public struct DeferredHandoverSectionedResultsChangeset<Upstream: Publisher, T: RealmSectionedResult, S: Scheduler>: Publisher where Upstream.Output == SectionedResultsChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    private let scheduler: S
    init(_ upstream: Upstream, _ scheduler: S)
    {
      self.upstream = upstream
      self.scheduler = scheduler
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      upstream
        .map { SectionedHandover<T, S>($0) }
        .receive(on: scheduler)
        .compactMap { $0.resolve(scheduler) }
        .receive(subscriber: subscriber)
    }
  }

  // swiftlint:enable type_name

  /// A publisher which delivers thread-confined collection changesets to a
  /// serial dispatch queue.
  ///
  /// Create using `.threadSafeReference().receive(on: queue)` on a publisher
  /// that emits `SectionedResultsChange`.
  @frozen public struct DeferredHandoverSectionChangeset<Upstream: Publisher, T: RealmSectionedResult, S: Scheduler>: Publisher where Upstream.Output == SectionedResultsChange<T>
  {
    /// :nodoc:
    public typealias Failure = Upstream.Failure
    /// :nodoc:
    public typealias Output = Upstream.Output

    private let upstream: Upstream
    private let scheduler: S
    init(_ upstream: Upstream, _ scheduler: S)
    {
      self.upstream = upstream
      self.scheduler = scheduler
    }

    /// :nodoc:
    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input
    {
      let scheduler = scheduler
      upstream
        .map { SectionedHandover<T, S>($0) }
        .receive(on: scheduler)
        .compactMap { $0.resolve(scheduler) }
        .receive(subscriber: subscriber)
    }
  }
}
