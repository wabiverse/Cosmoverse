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

private func isSameCollection(_ lhs: RLMCollection, _ rhs: Any) -> Bool
{
  // Managed isEqual checks if they're backed by the same core field, so it does exactly what we need
  if lhs.realm != nil
  {
    return lhs.isEqual(rhs)
  }
  // For unmanaged we want to check if the backing collection is the same instance
  if let rhs = rhs as? RLMSwiftCollectionBase
  {
    return lhs === rhs._rlmCollection
  }
  return lhs === rhs as AnyObject
}

protocol MutableRealmCollection
{
  func assign(_ value: Any)

  /// Unmanaged collection properties need a reference to their parent object for
  /// KVO to work because the mutation is done via the collection object but the
  /// observation is on the parent.
  func setParent(_ object: RLMObjectBase, _ property: RLMProperty)
}

extension List: MutableRealmCollection
{
  func assign(_ value: Any)
  {
    guard !isSameCollection(_rlmCollection, value) else { return }
    RLMAssignToCollection(_rlmCollection, value)
  }

  func setParent(_ object: RLMObjectBase, _ property: RLMProperty)
  {
    rlmArray.setParent(object, property: property)
  }
}

extension MutableSet: MutableRealmCollection
{
  func assign(_ value: Any)
  {
    guard !isSameCollection(_rlmCollection, value) else { return }
    RLMAssignToCollection(_rlmCollection, value)
  }

  func setParent(_ object: RLMObjectBase, _ property: RLMProperty)
  {
    rlmSet.setParent(object, property: property)
  }
}

extension Map: MutableRealmCollection
{
  func assign(_ value: Any)
  {
    guard !isSameCollection(_rlmCollection, value) else { return }
    rlmDictionary.setDictionary(value)
  }

  func setParent(_ object: RLMObjectBase, _ property: RLMProperty)
  {
    rlmDictionary.setParent(object, property: property)
  }
}
