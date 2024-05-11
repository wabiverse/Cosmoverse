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
 `LinkingObjects` is an auto-updating container type. It represents zero or more objects that are linked to its owning
 model object through a property relationship.

 `LinkingObjects` can be queried with the same predicates as `List<Element>` and `Results<Element>`.

 `LinkingObjects` always reflects the current state of the Realm on the current thread, including during write
 transactions on the current thread. The one exception to this is when using `for...in` enumeration, which will always
 enumerate over the linking objects that were present when the enumeration is begun, even if some of them are deleted or
 modified to no longer link to the target object during the enumeration.

 `LinkingObjects` can only be used as a property on `Object` models.
 */
@frozen public struct LinkingObjects<Element: ObjectBase & RealmCollectionValue>: RealmCollectionImpl
{
  // MARK: Initializers

  /**
   Creates an instance of a `LinkingObjects`. This initializer should only be called when declaring a property on a
   Realm model.

   - parameter type:         The type of the object owning the property the linking objects should refer to.
   - parameter propertyName: The property name of the property the linking objects should refer to.
   */
  public init(fromType _: Element.Type, property propertyName: String)
  {
    self.propertyName = propertyName
  }

  /// A human-readable description of the objects represented by the linking objects.
  public var description: String
  {
    if realm == nil
    {
      var this = self
      return withUnsafePointer(to: &this)
      {
        "LinkingObjects<\(Element.className())> <\($0)> (\n\n)"
      }
    }
    return RLMDescriptionWithMaxDepth("LinkingObjects", collection, RLMDescriptionMaxDepth)
  }

  // MARK: Object Retrieval

  /**
   Returns the object at the given `index`.

   - parameter index: The index.
   */
  public subscript(index: Int) -> Element
  {
    if let lastAccessedNames
    {
      return Element.keyPathRecorder(with: lastAccessedNames)
    }
    throwForNegativeIndex(index)
    return collection[UInt(index)] as! Element
  }

  // MARK: Equatable

  public static func == (lhs: LinkingObjects<Element>, rhs: LinkingObjects<Element>) -> Bool
  {
    lhs.collection.isEqual(rhs.collection)
  }

  // MARK: Implementation

  init(propertyName: String, handle: RLMLinkingObjectsHandle?)
  {
    self.propertyName = propertyName
    self.handle = handle
  }

  init(collection: RLMCollection)
  {
    propertyName = ""
    handle = RLMLinkingObjectsHandle(linkingObjects: collection as! RLMResults<AnyObject>)
  }

  var collection: RLMCollection
  {
    handle?.results ?? RLMResults<AnyObject>.emptyDetached()
  }

  var propertyName: String
  var handle: RLMLinkingObjectsHandle?
  var lastAccessedNames: NSMutableArray?

  /// :nodoc:
  public func makeIterator() -> RLMIterator<Element>
  {
    RLMIterator(collection: collection)
  }
}
