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
import Realm.Private

/// Enum representing an option for `String` queries.
public struct StringOptions: OptionSet, Sendable
{
  /// :doc:
  public let rawValue: Int8
  /// :doc:
  public init(rawValue: Int8)
  {
    self.rawValue = rawValue
  }

  /// A case-insensitive search.
  public static let caseInsensitive = StringOptions(rawValue: 1)
  /// Query ignores diacritic marks.
  public static let diacriticInsensitive = StringOptions(rawValue: 2)
}

/**
 `Query` is a class used to create type-safe query predicates.

 With `Query` you are given the ability to create Swift style query expression that will then
 be constructed into an `NSPredicate`. The `Query` class should not be instantiated directly
 and should be only used as a parameter within a closure that takes a query expression as an argument.
 Example:
 ```swift
 public func where(_ query: ((Query<Element>) -> Query<Element>)) -> Results<Element>
 ```

 You would then use the above function like so:
 ```swift
 let results = realm.objects(Person.self).query {
    $0.name == "Foo" || $0.name == "Bar" && $0.age >= 21
 }
 ```

 ## Supported predicate types

 ### Prefix
 - NOT `!`
 ```swift
 let results = realm.objects(Person.self).query {
    !$0.dogsName.contains("Fido") || !$0.name.contains("Foo")
 }
 ```

 ### Comparisions
 - Equals `==`
 - Not Equals `!=`
 - Greater Than `>`
 - Less Than `<`
 - Greater Than or Equal `>=`
 - Less Than or Equal `<=`
 - Between `.contains(_ range:)`

 ### Collections
 - IN `.contains(_ element:)`
 - Between `.contains(_ range:)`

 ### Map
 - @allKeys `.keys`
 - @allValues `.values`

 ### Compound
 - AND `&&`
 - OR `||`

 ### Collection Aggregation
 - @avg `.avg`
 - @min `.min`
 - @max `.max`
 - @sum `.sum`
 - @count `.count`
 ```swift
 let results = realm.objects(Person.self).query {
    !$0.dogs.age.avg >= 0 || !$0.dogsAgesArray.avg >= 0
 }
 ```

 ### Other
 - NOT `!`
 - Subquery `($0.fooList.intCol >= 5).count > n`

 */
@dynamicMemberLookup
public struct Query<T>
{
  /// This initaliser should be used from callers who require queries on primitive collections.
  /// - Parameter isPrimitive: True if performing a query on a primitive collection.
  init(isPrimitive: Bool = false)
  {
    if isPrimitive
    {
      node = .keyPath(["self"], options: [.isCollection])
    }
    else
    {
      node = .keyPath([], options: [])
    }
  }

  private let node: QueryNode

  /**
   The `Query` struct works by compounding `QueryNode`s together in a tree structure.
   Each part of a query expression will be represented by one of the below static methods.
   For example in the simple expression `stringCol == 'Foo'`:

   The first static method that will be called from inside the query
   closure is `subscript<V>(dynamicMember member: KeyPath<T, V>)`
   this will extract the `stringCol` keypath. The last static method to be called in this expression is
   `func == <V>(_ lhs: Query<V>, _ rhs: V)` where the lhs is a `Query` which holds the `QueryNode`
   keyPath for `stringCol`. The rhs will be expressed as a constant in `QueryNode` and a tree will be built
   to represent an equals comparison.

   To build the tree we will do:
   ```
   Query<Bool>(.comparison(operator: .equal, lhs.node, .constant(rhs), options: []))
   ```
   This sets the comparison node as the root node for the expression and the new `Query` struct will be returned.

   When it comes time to build the predicate string with its arguments call `_constructPredicate()`. This will
   recursively traverse the tree and build the NSPredicate compatible string.
   */
  private init(_ node: QueryNode)
  {
    self.node = node
  }

  private func appendKeyPath(_ keyPath: String, options: KeyPathOptions) -> QueryNode
  {
    if case let .keyPath(kp, ops) = node
    {
      return .keyPath(kp + [keyPath], options: ops.union(options))
    }
    else if case .mapSubscript = node
    {
      throwRealmException("Cannot apply key path to Map subscripts.")
    }
    throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
  }

  private func buildCollectionAggregateKeyPath(_ aggregate: String) -> QueryNode
  {
    if case let .keyPath(kp, options) = node
    {
      var keyPaths = kp
      if keyPaths.count > 1
      {
        keyPaths.insert(aggregate, at: 1)
      }
      else
      {
        keyPaths.append(aggregate)
      }
      return .keyPath(keyPaths, options: [options.subtracting(.requiresAny)])
    }
    throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
  }

  private func keyPathErasingAnyPrefix(appending keyPath: String? = nil) -> QueryNode
  {
    if case let .keyPath(kp, o) = node
    {
      if let keyPath
      {
        return .keyPath(kp + [keyPath], options: [o.subtracting(.requiresAny)])
      }
      return .keyPath(kp, options: [o.subtracting(.requiresAny)])
    }
    throwRealmException("Cannot apply a keypath to \(buildPredicate(node))")
  }

  // MARK: Comparable

  /// :nodoc:
  public static func == (_ lhs: Query, _ rhs: T) -> Query<Bool>
  {
    .init(.comparison(operator: .equal, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  public static func == (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .equal, lhs.node, rhs.node, options: []))
  }

  /// :nodoc:
  public static func != (_ lhs: Query, _ rhs: T) -> Query<Bool>
  {
    .init(.comparison(operator: .notEqual, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  public static func != (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .notEqual, lhs.node, rhs.node, options: []))
  }

  // MARK: In

  /// Checks if the value is present in the collection.
  public func `in`(_ collection: some Sequence<T>) -> Query<Bool>
  {
    .init(.comparison(operator: .in, node, .constant(collection), options: []))
  }

  // MARK: Subscript

  /// :nodoc:
  public subscript<V>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase
  {
    .init(appendKeyPath(_name(for: member), options: []))
  }

  /// :nodoc:
  public subscript<V: RealmKeyedCollection>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase
  {
    .init(appendKeyPath(_name(for: member), options: [.isCollection, .requiresAny]))
  }

  /// :nodoc:
  public subscript<V: RealmCollectionBase>(dynamicMember member: KeyPath<T, V>) -> Query<V> where T: ObjectBase
  {
    .init(appendKeyPath(_name(for: member), options: [.isCollection, .requiresAny]))
  }

  // MARK: Query Construction

  /// For testing purposes only. Do not use directly.
  public static func _constructForTesting() -> Query<T>
  {
    Query<T>()
  }

  /// Constructs an NSPredicate compatible string with its accompanying arguments.
  /// - Note: This is for internal use only and is exposed for testing purposes.
  public func _constructPredicate() -> (String, [Any])
  {
    buildPredicate(node)
  }

  // Creates an NSPredicate compatible string.
  // - Returns: A tuple containing the predicate string and an array of arguments.

  /// Creates an NSPredicate from the query expression.
  var predicate: NSPredicate
  {
    let predicate = _constructPredicate()
    return NSPredicate(format: predicate.0, argumentArray: predicate.1)
  }
}

// MARK: Numerics

public extension Query where T: _HasPersistedType, T.PersistedType: _QueryNumeric
{
  /// :nodoc:
  static func > (_ lhs: Query, _ rhs: T) -> Query<Bool>
  {
    .init(.comparison(operator: .greaterThan, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func > (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .greaterThan, lhs.node, rhs.node, options: []))
  }

  /// :nodoc:
  static func >= (_ lhs: Query, _ rhs: T) -> Query<Bool>
  {
    .init(.comparison(operator: .greaterThanEqual, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func >= (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .greaterThanEqual, lhs.node, rhs.node, options: []))
  }

  /// :nodoc:
  static func < (_ lhs: Query, _ rhs: T) -> Query<Bool>
  {
    .init(.comparison(operator: .lessThan, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func < (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .lessThan, lhs.node, rhs.node, options: []))
  }

  /// :nodoc:
  static func <= (_ lhs: Query, _ rhs: T) -> Query<Bool>
  {
    .init(.comparison(operator: .lessThanEqual, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func <= (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .lessThanEqual, lhs.node, rhs.node, options: []))
  }
}

// MARK: Compound

public extension Query where T == Bool
{
  /// :nodoc:
  static prefix func ! (_ query: Query) -> Query<Bool>
  {
    .init(.not(query.node))
  }

  /// :nodoc:
  static func && (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .and, lhs.node, rhs.node, options: []))
  }

  /// :nodoc:
  static func || (_ lhs: Query, _ rhs: Query) -> Query<Bool>
  {
    .init(.comparison(operator: .or, lhs.node, rhs.node, options: []))
  }
}

// MARK: OptionalProtocol

public extension Query where T: OptionalProtocol
{
  /// :nodoc:
  subscript<V>(dynamicMember member: KeyPath<T.Wrapped, V>) -> Query<V> where T.Wrapped: ObjectBase
  {
    .init(appendKeyPath(_name(for: member), options: []))
  }
}

// MARK: RealmCollection

public extension Query where T: RealmCollection
{
  /// :nodoc:
  subscript<V>(dynamicMember member: KeyPath<T.Element, V>) -> Query<V> where T.Element: ObjectBase
  {
    .init(appendKeyPath(_name(for: member), options: []))
  }

  /// Query the count of the objects in the collection.
  var count: Query<Int>
  {
    .init(keyPathErasingAnyPrefix(appending: "@count"))
  }
}

public extension Query where T: RealmCollection
{
  /// Checks if an element exists in this collection.
  func contains(_ value: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .in, .constant(value), keyPathErasingAnyPrefix(), options: []))
  }

  /// Checks if any elements contained in the given array are present in the collection.
  func containsAny(in collection: some Sequence<T.Element>) -> Query<Bool>
  {
    .init(.comparison(operator: .in, node, .constant(collection), options: []))
  }
}

public extension Query where T: RealmCollection, T.Element: Comparable
{
  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: Range<T.Element>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }

  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: ClosedRange<T.Element>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }
}

public extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: Comparable
{
  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: Range<T.Element.Wrapped>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }

  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: ClosedRange<T.Element.Wrapped>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }
}

public extension Query where T: RealmCollection
{
  /// :nodoc:
  static func == (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .equal, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func != (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .notEqual, lhs.node, .constant(rhs), options: []))
  }
}

public extension Query where T: RealmCollection, T.Element.PersistedType: _QueryNumeric
{
  /// :nodoc:
  static func > (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .greaterThan, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func >= (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .greaterThanEqual, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func < (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .lessThan, lhs.node, .constant(rhs), options: []))
  }

  /// :nodoc:
  static func <= (_ lhs: Query<T>, _ rhs: T.Element) -> Query<Bool>
  {
    .init(.comparison(operator: .lessThanEqual, lhs.node, .constant(rhs), options: []))
  }

  /// Returns the minimum value in the collection.
  var min: Query<T.Element>
  {
    .init(keyPathErasingAnyPrefix(appending: "@min"))
  }

  /// Returns the maximum value in the collection.
  var max: Query<T.Element>
  {
    .init(keyPathErasingAnyPrefix(appending: "@max"))
  }

  /// Returns the average in the collection.
  var avg: Query<T.Element>
  {
    .init(keyPathErasingAnyPrefix(appending: "@avg"))
  }

  /// Returns the sum of all the values in the collection.
  var sum: Query<T.Element>
  {
    .init(keyPathErasingAnyPrefix(appending: "@sum"))
  }
}

// MARK: RealmKeyedCollection

public extension Query where T: RealmKeyedCollection
{
  /// Checks if any elements contained in the given array are present in the map's values.
  func containsAny(in collection: some Sequence<T.Value>) -> Query<Bool>
  {
    .init(.comparison(operator: .in, node, .constant(collection), options: []))
  }

  /// Checks if an element exists in this collection.
  func contains(_ value: T.Value) -> Query<Bool>
  {
    .init(.comparison(operator: .in, .constant(value), keyPathErasingAnyPrefix(), options: []))
  }

  /// Allows a query over all values in the Map.
  var values: Query<T.Value>
  {
    .init(appendKeyPath("@allValues", options: []))
  }

  /// :nodoc:
  subscript(member: T.Key) -> Query<T.Value>
  {
    .init(.mapSubscript(keyPathErasingAnyPrefix(), key: member))
  }
}

public extension Query where T: RealmKeyedCollection, T.Key == String
{
  /// Allows a query over all keys in the `Map`.
  var keys: Query<String>
  {
    .init(appendKeyPath("@allKeys", options: []))
  }
}

public extension Query where T: RealmKeyedCollection, T.Value: Comparable
{
  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: Range<T.Value>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }

  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: ClosedRange<T.Value>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }
}

public extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: Comparable
{
  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: Range<T.Value.Wrapped>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThan, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }

  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: ClosedRange<T.Value.Wrapped>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, keyPathErasingAnyPrefix(appending: "@min"), .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThanEqual, keyPathErasingAnyPrefix(appending: "@max"), .constant(range.upperBound), options: []), options: []))
  }
}

public extension Query where T: RealmKeyedCollection, T.Value.PersistedType: _QueryNumeric
{
  /// Returns the minimum value in the keyed collection.
  var min: Query<T.Value>
  {
    .init(keyPathErasingAnyPrefix(appending: "@min"))
  }

  /// Returns the maximum value in the keyed collection.
  var max: Query<T.Value>
  {
    .init(keyPathErasingAnyPrefix(appending: "@max"))
  }

  /// Returns the average in the keyed collection.
  var avg: Query<T.Value>
  {
    .init(keyPathErasingAnyPrefix(appending: "@avg"))
  }

  /// Returns the sum of all the values in the keyed collection.
  var sum: Query<T.Value>
  {
    .init(keyPathErasingAnyPrefix(appending: "@sum"))
  }
}

public extension Query where T: RealmKeyedCollection
{
  /// Returns the count of all the values in the keyed collection.
  var count: Query<Int>
  {
    .init(keyPathErasingAnyPrefix(appending: "@count"))
  }
}

// MARK: - PersistableEnum

public extension Query where T: PersistableEnum, T.RawValue: _RealmSchemaDiscoverable
{
  /// Query on the rawValue of the Enum rather than the Enum itself.
  ///
  /// This can be used to write queries which can be expressed on the
  /// RawValue but not the enum. For example, this lets you query for
  /// `.starts(with:)` on a string enum where the prefix is not a member of
  /// the enum.
  var rawValue: Query<T.RawValue>
  {
    .init(node)
  }
}

public extension Query where T: OptionalProtocol, T.Wrapped: PersistableEnum, T.Wrapped.RawValue: _RealmSchemaDiscoverable
{
  /// Query on the rawValue of the Enum rather than the Enum itself.
  ///
  /// This can be used to write queries which can be expressed on the
  /// RawValue but not the enum. For example, this lets you query for
  /// `.starts(with:)` on a string enum where the prefix is not a member of
  /// the enum.
  var rawValue: Query<T.Wrapped.RawValue?>
  {
    .init(node)
  }
}

/// The actual collection type returned in these doesn't matter because it's
/// only used to constrain the set of operations available, and the collections
/// all have the same operations.
public extension Query where T: RealmCollection, T.Element: PersistableEnum, T.Element.RawValue: RealmCollectionValue
{
  /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
  ///
  /// This can be used to write queries which can be expressed on the
  /// RawValue but not the enum. For example, this lets you query for
  /// `.starts(with:)` on a string enum where the prefix is not a member of
  /// the enum.
  var rawValue: Query<AnyRealmCollection<T.Element.RawValue>>
  {
    .init(node)
  }
}

public extension Query where T: RealmKeyedCollection, T.Value: PersistableEnum, T.Value.RawValue: RealmCollectionValue
{
  /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
  ///
  /// This can be used to write queries which can be expressed on the
  /// RawValue but not the enum. For example, this lets you query for
  /// `.starts(with:)` on a string enum where the prefix is not a member of
  /// the enum.
  var rawValue: Query<Map<T.Key, T.Value.RawValue>>
  {
    .init(node)
  }
}

public extension Query where T: RealmCollection, T.Element: OptionalProtocol, T.Element.Wrapped: PersistableEnum, T.Element.Wrapped.RawValue: _RealmCollectionValueInsideOptional
{
  /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
  ///
  /// This can be used to write queries which can be expressed on the
  /// RawValue but not the enum. For example, this lets you query for
  /// `.starts(with:)` on a string enum where the prefix is not a member of
  /// the enum.
  var rawValue: Query<AnyRealmCollection<T.Element.Wrapped.RawValue?>>
  {
    .init(node)
  }
}

public extension Query where T: RealmKeyedCollection, T.Value: OptionalProtocol, T.Value.Wrapped: PersistableEnum, T.Value.Wrapped.RawValue: _RealmCollectionValueInsideOptional
{
  /// Query on the rawValue of the Enums in the collection rather than the Enums themselves.
  ///
  /// This can be used to write queries which can be expressed on the
  /// RawValue but not the enum. For example, this lets you query for
  /// `.starts(with:)` on a string enum where the prefix is not a member of
  /// the enum.
  var rawValue: Query<Map<T.Key, T.Value.Wrapped.RawValue?>>
  {
    .init(node)
  }
}

// MARK: - CustomPersistable

public extension Query where T: _HasPersistedType
{
  /// Query on the persistableValue of the value rather than the value itself.
  ///
  /// This can be used to write queries which can be expressed on the
  /// persisted type but not on the type itself, such as range queries
  /// on the persistable value or to query for values which can't be
  /// converted to the mapped type.
  ///
  /// For types which don't conform to PersistableEnum, CustomPersistable or
  /// FailableCustomPersistable this doesn't do anything useful.
  var persistableValue: Query<T.PersistedType>
  {
    .init(node)
  }
}

/// The actual collection type returned in these doesn't matter because it's
/// only used to constrain the set of operations available, and the collections
/// all have the same operations.
public extension Query where T: RealmCollection
{
  /// Query on the persistableValue of the values in the collection rather
  /// than the values themselves.
  ///
  /// This can be used to write queries which can be expressed on the
  /// persisted type but not on the type itself, such as range queries
  /// on the persistable value or to query for values which can't be
  /// converted to the mapped type.
  ///
  /// For types which don't conform to PersistableEnum, CustomPersistable or
  /// FailableCustomPersistable this doesn't do anything useful.
  var persistableValue: Query<AnyRealmCollection<T.Element.PersistedType>>
  {
    .init(node)
  }
}

public extension Query where T: RealmKeyedCollection
{
  /// Query on the persistableValue of the values in the collection rather
  /// than the values themselves.
  ///
  /// This can be used to write queries which can be expressed on the
  /// persisted type but not on the type itself, such as range queries
  /// on the persistable value or to query for values which can't be
  /// converted to the mapped type.
  ///
  /// For types which don't conform to PersistableEnum, CustomPersistable or
  /// FailableCustomPersistable this doesn't do anything useful.
  var persistableValue: Query<Map<T.Key, T.Value.PersistedType>>
  {
    .init(node)
  }
}

// MARK: _QueryNumeric

public extension Query where T: Comparable
{
  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: Range<T>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, node, .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThan, node, .constant(range.upperBound), options: []), options: []))
  }

  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: ClosedRange<T>) -> Query<Bool>
  {
    .init(.between(node,
                   lowerBound: .constant(range.lowerBound),
                   upperBound: .constant(range.upperBound)))
  }
}

// MARK: _QueryString

public extension Query where T: _HasPersistedType, T.PersistedType: _QueryString
{
  /**
   Checks for all elements in this collection that equal the given value.
   `?` and `*` are allowed as wildcard characters, where `?` matches 1 character and `*` matches 0 or more characters.
   - parameter value: value used.
   - parameter caseInsensitive: `true` if it is a case-insensitive search.
   */
  func like(_ value: T, caseInsensitive: Bool = false) -> Query<Bool>
  {
    .init(.comparison(operator: .like, node, .constant(value), options: caseInsensitive ? [.caseInsensitive] : []))
  }

  /**
   Checks for all elements in this collection that equal the given value.
   `?` and `*` are allowed as wildcard characters, where `?` matches 1 character and `*` matches 0 or more characters.
   - parameter value: value used.
   - parameter caseInsensitive: `true` if it is a case-insensitive search.
   */
  func like(_ column: Query<some Any>, caseInsensitive: Bool = false) -> Query<Bool>
  {
    .init(.comparison(operator: .like, node, column.node, options: caseInsensitive ? [.caseInsensitive] : []))
  }
}

// MARK: _QueryBinary

public extension Query where T: _HasPersistedType, T.PersistedType: _QueryBinary
{
  /**
   Checks for all elements in this collection that contains the given value.
   - parameter value: value used.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func contains(_ value: T, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .contains, node, .constant(value), options: options))
  }

  /**
   Compares that this column contains a value in another column.
   - parameter column: The other column.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func contains<U>(_ column: Query<U>, options: StringOptions = []) -> Query<Bool> where U: _Persistable, U.PersistedType: _QueryBinary
  {
    .init(.comparison(operator: .contains, node, column.node, options: options))
  }

  /**
   Checks for all elements in this collection that starts with the given value.
   - parameter value: value used.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func starts(with value: T, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .beginsWith, node, .constant(value), options: options))
  }

  /**
   Compares that this column starts with a value in another column.
   - parameter column: The other column.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func starts(with column: Query<some Any>, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .beginsWith, node, column.node, options: options))
  }

  /**
   Checks for all elements in this collection that ends with the given value.
   - parameter value: value used.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func ends(with value: T, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .endsWith, node, .constant(value), options: options))
  }

  /**
   Compares that this column ends with a value in another column.
   - parameter column: The other column.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func ends(with column: Query<some Any>, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .endsWith, node, column.node, options: options))
  }

  /**
   Checks for all elements in this collection that equals the given value.
   - parameter value: value used.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func equals(_ value: T, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .equal, node, .constant(value), options: options))
  }

  /**
   Compares that this column is equal to the value in another given column.
   - parameter column: The other column.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func equals(_ column: Query<some Any>, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .equal, node, column.node, options: options))
  }

  /**
   Checks for all elements in this collection that are not equal to the given value.
   - parameter value: value used.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func notEquals(_ value: T, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .notEqual, node, .constant(value), options: options))
  }

  /**
   Compares that this column is not equal to the value in another given column.
   - parameter column: The other column.
   - parameter options: A Set of options used to evaluate the search query.
   */
  func notEquals(_ column: Query<some Any>, options: StringOptions = []) -> Query<Bool>
  {
    .init(.comparison(operator: .notEqual, node, column.node, options: options))
  }
}

public extension Query where T: OptionalProtocol, T.Wrapped: Comparable
{
  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: Range<T.Wrapped>) -> Query<Bool>
  {
    .init(.comparison(operator: .and,
                      .comparison(operator: .greaterThanEqual, node, .constant(range.lowerBound), options: []),
                      .comparison(operator: .lessThan, node, .constant(range.upperBound), options: []), options: []))
  }

  /// Checks for all elements in this collection that are within a given range.
  func contains(_ range: ClosedRange<T.Wrapped>) -> Query<Bool>
  {
    .init(.between(node,
                   lowerBound: .constant(range.lowerBound),
                   upperBound: .constant(range.upperBound)))
  }
}

// MARK: Subquery

public extension Query where T == Bool
{
  /// Completes a subquery expression.
  /// - Usage:
  /// ```
  /// (($0.myCollection.age >= 21) && ($0.myCollection.siblings == 4))).count >= 5
  /// ```
  /// - Note:
  /// Do not mix collections within a subquery expression. It is
  /// only permitted to reference a single collection per each subquery.
  var count: Query<Int>
  {
    .init(.subqueryCount(node))
  }
}

// MARK: Keypath Collection Aggregates

/**
 You can use only use aggregates in numeric types where the root keypath is a collection.
 ```swift
 let results = realm.objects(Person.self).query {
    !$0.dogs.age.avg >= 0
 }
 ```
 Where `dogs` is an array of objects.
 */
public extension Query where T: _HasPersistedType, T.PersistedType: _QueryNumeric
{
  /// Returns the minimum value of the objects in the collection based on the keypath.
  var min: Query
  {
    Query(buildCollectionAggregateKeyPath("@min"))
  }

  /// Returns the maximum value of the objects in the collection based on the keypath.
  var max: Query
  {
    Query(buildCollectionAggregateKeyPath("@max"))
  }

  /// Returns the average of the objects in the collection based on the keypath.
  var avg: Query
  {
    Query(buildCollectionAggregateKeyPath("@avg"))
  }

  /// Returns the sum of the objects in the collection based on the keypath.
  var sum: Query
  {
    Query(buildCollectionAggregateKeyPath("@sum"))
  }
}

public extension Query where T: OptionalProtocol, T.Wrapped: EmbeddedObject
{
  /**
   Use `geoWithin` function to filter objects whose location points lie within a certain area,
   using a Geospatial shape (`GeoBox`, `GeoPolygon` or `GeoCircle`).

    - note: There is no dedicated type to store Geospatial points, instead points should be stored as
    [GeoJson-shaped](https://www.mongodb.com/docs/manual/reference/geojson/)
    embedded object. Geospatial queries (`geoWithin`) can only be executed
    in such a type of objects and will throw otherwise.
    - see: `GeoPoint`
   */
  func geoWithin(_ value: some RLMGeospatial) -> Query<Bool>
  {
    .init(.geoWithin(node, .constant(value)))
  }
}

/// Tag protocol for all numeric types.
public protocol _QueryNumeric: _RealmSchemaDiscoverable {}
extension Int: _QueryNumeric {}
extension Int8: _QueryNumeric {}
extension Int16: _QueryNumeric {}
extension Int32: _QueryNumeric {}
extension Int64: _QueryNumeric {}
extension Float: _QueryNumeric {}
extension Double: _QueryNumeric {}
extension Decimal128: _QueryNumeric {}
extension Date: _QueryNumeric {}
extension AnyRealmValue: _QueryNumeric {}
extension Optional: _QueryNumeric where Wrapped: _Persistable, Wrapped.PersistedType: _QueryNumeric {}

/// Tag protocol for all types that are compatible with `String`.
public protocol _QueryString: _QueryBinary {}
extension String: _QueryString {}
extension Optional: _QueryString where Wrapped: _Persistable, Wrapped.PersistedType: _QueryString {}

/// Tag protocol for all types that are compatible with `Binary`.
public protocol _QueryBinary {}
extension Data: _QueryBinary {}
extension Optional: _QueryBinary where Wrapped: _Persistable, Wrapped.PersistedType: _QueryBinary {}

// MARK: QueryNode -

private indirect enum QueryNode
{
  enum Operator: String
  {
    case or = "||"
    case and = "&&"
    case equal = "=="
    case notEqual = "!="
    case lessThan = "<"
    case lessThanEqual = "<="
    case greaterThan = ">"
    case greaterThanEqual = ">="
    case `in` = "IN"
    case contains = "CONTAINS"
    case beginsWith = "BEGINSWITH"
    case endsWith = "ENDSWITH"
    case like = "LIKE"
  }

  case not(_ child: QueryNode)
  case constant(_ value: Any?)

  case keyPath(_ value: [String], options: KeyPathOptions)

  case comparison(operator: Operator, _ lhs: QueryNode, _ rhs: QueryNode, options: StringOptions)
  case between(_ lhs: QueryNode, lowerBound: QueryNode, upperBound: QueryNode)

  case subqueryCount(_ child: QueryNode)
  case mapSubscript(_ keyPath: QueryNode, key: Any)
  case geoWithin(_ keyPath: QueryNode, _ value: QueryNode)
}

private func buildPredicate(_ root: QueryNode, subqueryCount: Int = 0) -> (String, [Any])
{
  let formatStr = NSMutableString()
  let arguments = NSMutableArray()
  var subqueryCounter = subqueryCount

  func buildExpression(_ lhs: QueryNode,
                       _ op: String,
                       _ rhs: QueryNode,
                       prefix: String? = nil)
  {
    if case let .keyPath(_, lhsOptions) = lhs,
       case let .keyPath(_, rhsOptions) = rhs,
       lhsOptions.contains(.isCollection), rhsOptions.contains(.isCollection)
    {
      throwRealmException("Comparing two collection columns is not permitted.")
    }
    formatStr.append("(")
    if let prefix
    {
      formatStr.append(prefix)
    }
    build(lhs)
    formatStr.append(" \(op) ")
    build(rhs)
    formatStr.append(")")
  }

  func buildCompoundExpression(_ lhs: QueryNode,
                               _ op: String,
                               _ rhs: QueryNode,
                               prefix: String? = nil)
  {
    if let prefix
    {
      formatStr.append(prefix)
    }
    formatStr.append("(")
    build(lhs, isNewNode: true)
    formatStr.append(" \(op) ")
    build(rhs, isNewNode: true)
    formatStr.append(")")
  }

  func buildBetween(_ lowerBound: QueryNode, _ upperBound: QueryNode)
  {
    formatStr.append(" BETWEEN {")
    build(lowerBound)
    formatStr.append(", ")
    build(upperBound)
    formatStr.append("}")
  }

  func buildBool(_ node: QueryNode, isNot: Bool = false)
  {
    if case let .keyPath(kp, _) = node
    {
      formatStr.append(kp.joined(separator: "."))
      formatStr.append(" == \(isNot ? "false" : "true")")
    }
  }

  func strOptions(_ options: StringOptions) -> String
  {
    if options == []
    {
      return ""
    }
    return "[\(options.contains(.caseInsensitive) ? "c" : "")\(options.contains(.diacriticInsensitive) ? "d" : "")]"
  }

  func build(_ node: QueryNode, prefix: String? = nil, isNewNode: Bool = false)
  {
    switch node
    {
      case let .constant(value):
        formatStr.append("%@")
        arguments.add(value ?? NSNull())
      case let .keyPath(kp, options):
        if isNewNode
        {
          buildBool(node)
          return
        }
        if options.contains(.requiresAny)
        {
          formatStr.append("ANY ")
        }
        formatStr.append(kp.joined(separator: "."))
      case let .not(child):
        if case .keyPath = child,
           isNewNode
        {
          buildBool(child, isNot: true)
          return
        }
        build(child, prefix: "NOT ")
      case let .comparison(operator: op, lhs, rhs, options):
        switch op
        {
          case .and, .or:
            buildCompoundExpression(lhs, op.rawValue, rhs, prefix: prefix)
          default:
            buildExpression(lhs, "\(op.rawValue)\(strOptions(options))", rhs, prefix: prefix)
        }
      case let .between(lhs, lowerBound, upperBound):
        formatStr.append("(")
        build(lhs)
        buildBetween(lowerBound, upperBound)
        formatStr.append(")")
      case let .subqueryCount(inner):
        subqueryCounter += 1
        let (collectionName, node) = SubqueryRewriter.rewrite(inner, subqueryCounter)
        formatStr.append("SUBQUERY(\(collectionName), $col\(subqueryCounter), ")
        build(node)
        formatStr.append(").@count")
      case let .mapSubscript(keyPath, key):
        build(keyPath)
        formatStr.append("[%@]")
        arguments.add(key)
      case let .geoWithin(keyPath, value):
        buildExpression(keyPath, QueryNode.Operator.in.rawValue, value, prefix: nil)
    }
  }
  build(root, isNewNode: true)
  return (formatStr as String, (arguments as! [Any]))
}

private struct KeyPathOptions: OptionSet
{
  let rawValue: Int8
  init(rawValue: RawValue)
  {
    self.rawValue = rawValue
  }

  static let isCollection = KeyPathOptions(rawValue: 1)
  static let requiresAny = KeyPathOptions(rawValue: 2)
}

private struct SubqueryRewriter
{
  private var collectionName: String?
  private var counter: Int
  private mutating func rewrite(_ node: QueryNode) -> QueryNode
  {
    switch node
    {
      case let .keyPath(kp, options):
        if options.contains(.isCollection)
        {
          precondition(!kp.isEmpty)
          collectionName = kp[0]
          var copy = kp
          copy[0] = "$col\(counter)"
          return .keyPath(copy, options: [.isCollection])
        }
        return node
      case let .not(child):
        return .not(rewrite(child))
      case let .comparison(operator: op, lhs, rhs, options: options):
        return .comparison(operator: op, rewrite(lhs), rewrite(rhs), options: options)
      case let .between(lhs, lowerBound, upperBound):
        return .between(rewrite(lhs), lowerBound: rewrite(lowerBound), upperBound: rewrite(upperBound))
      case let .subqueryCount(inner):
        return .subqueryCount(inner)
      case .constant:
        return node
      case .mapSubscript:
        throwRealmException("Subqueries do not support map subscripts.")
      case let .geoWithin(keyPath, value):
        return .geoWithin(keyPath, value)
    }
  }

  fileprivate static func rewrite(_ node: QueryNode, _ counter: Int) -> (String, QueryNode)
  {
    var rewriter = SubqueryRewriter(counter: counter)
    let rewritten = rewriter.rewrite(node)
    guard let collectionName = rewriter.collectionName
    else
    {
      throwRealmException("Subqueries must contain a keypath starting with a collection.")
    }
    return (collectionName, rewritten)
  }
}
