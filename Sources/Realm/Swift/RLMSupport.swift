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

public extension RLMRealm
{
  /**
   Returns the schema version for a Realm at a given local URL.

   - see: `+ [RLMRealm schemaVersionAtURL:encryptionKey:error:]`
   */
  @nonobjc class func schemaVersion(at url: URL, usingEncryptionKey key: Data? = nil) throws -> UInt64
  {
    var error: NSError?
    let version = __schemaVersion(at: url, encryptionKey: key, error: &error)
    guard version != RLMNotVersioned else { throw error! }
    return version
  }

  /**
   Returns the same object as the one referenced when the `RLMThreadSafeReference` was first created,
   but resolved for the current Realm for this thread. Returns `nil` if this object was deleted after
   the reference was created.

   - see `- [RLMRealm resolveThreadSafeReference:]`
   */
  @nonobjc func resolve<Confined>(reference: RLMThreadSafeReference<Confined>) -> Confined?
  {
    __resolve(reference as! RLMThreadSafeReference<RLMThreadConfined>) as! Confined?
  }
}

public extension RLMObject
{
  /**
   Returns all objects of this object type matching the given predicate from the default Realm.

   - see `+ [RLMObject objectsWithPredicate:]`
   */
  class func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject>
  {
    objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
  }

  /**
   Returns all objects of this object type matching the given predicate from the specified Realm.

   - see `+ [RLMObject objectsInRealm:withPredicate:]`
   */
  class func objects(in realm: RLMRealm,
                     where predicateFormat: String,
                     _ args: CVarArg...) -> RLMResults<RLMObject>
  {
    objects(in: realm, with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
  }
}

/// A protocol defining iterator support for RLMArray, RLMSet & RLMResults.
public protocol _RLMCollectionIterator
{
  /**
   Returns a `RLMCollectionIterator` that yields successive elements in the collection.
   This enables support for sequence-style enumeration of `RLMObject` subclasses in Swift.
   */
  func makeIterator() -> RLMCollectionIterator
}

public extension _RLMCollectionIterator where Self: RLMCollection
{
  /// :nodoc:
  func makeIterator() -> RLMCollectionIterator
  {
    RLMCollectionIterator(self)
  }
}

/// :nodoc:
public typealias RLMDictionarySingleEntry = (key: String, value: RLMObject)
/// A protocol defining iterator support for RLMDictionary
public protocol _RLMDictionaryIterator
{
  /// :nodoc:
  func makeIterator() -> RLMDictionaryIterator
}

public extension _RLMDictionaryIterator where Self: RLMCollection
{
  /// :nodoc:
  func makeIterator() -> RLMDictionaryIterator
  {
    RLMDictionaryIterator(self)
  }
}

/// Sequence conformance for RLMArray, RLMDictionary, RLMSet and RLMResults is provided by RLMCollection's
/// `makeIterator()` implementation.
extension RLMArray: Sequence, _RLMCollectionIterator {}
extension RLMDictionary: Sequence, _RLMDictionaryIterator {}
extension RLMSet: Sequence, _RLMCollectionIterator {}
extension RLMResults: Sequence, _RLMCollectionIterator {}

/**
 This struct enables sequence-style enumeration for RLMObjects in Swift via `RLMCollection.makeIterator`
 */
public struct RLMCollectionIterator: IteratorProtocol
{
  private var iteratorBase: NSFastEnumerationIterator

  init(_ collection: RLMCollection)
  {
    iteratorBase = NSFastEnumerationIterator(collection)
  }

  public mutating func next() -> RLMObject?
  {
    iteratorBase.next() as! RLMObject?
  }
}

/**
 This struct enables sequence-style enumeration for RLMDictionary in Swift via `RLMDictionary.makeIterator`
 */
public struct RLMDictionaryIterator: IteratorProtocol
{
  private var iteratorBase: NSFastEnumerationIterator
  private let dictionary: RLMDictionary<AnyObject, AnyObject>

  init(_ collection: RLMCollection)
  {
    dictionary = collection as! RLMDictionary<AnyObject, AnyObject>
    iteratorBase = NSFastEnumerationIterator(collection)
  }

  public mutating func next() -> RLMDictionarySingleEntry?
  {
    let key = iteratorBase.next()
    if let key
    {
      return (key: key as Any, value: dictionary[key as AnyObject]) as? RLMDictionarySingleEntry
    }
    if key != nil
    {
      fatalError("unsupported key type")
    }
    return nil
  }
}

/// Swift query convenience functions
public extension RLMCollection
{
  /**
   Returns the index of the first object in the collection matching the predicate.
   */
  func indexOfObject(where predicateFormat: String, _ args: CVarArg...) -> UInt
  {
    guard let index = indexOfObject?(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    else
    {
      fatalError("This RLMCollection does not support indexOfObject(where:)")
    }
    return index
  }

  /**
   Returns all objects matching the given predicate in the collection.
   */
  func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<NSObject>
  {
    objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<NSObject>
  }
}

public extension RLMCollection
{
  /// Allows for subscript support with RLMDictionary.
  subscript(_ key: String) -> AnyObject?
  {
    get
    {
      (self as! RLMDictionary<NSString, AnyObject>).object(forKey: key as NSString)
    }
    set
    {
      (self as! RLMDictionary<NSString, AnyObject>).setObject(newValue, forKey: key as NSString)
    }
  }
}
