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

/**
 `ObjectiveCSupport` is a class providing methods for Swift/Objective-C interoperability.

 With `ObjectiveCSupport` you can either retrieve the internal ObjC representations of the Realm objects,
 or wrap ObjC Realm objects with their Swift equivalents.

 Use this to provide public APIs that support both platforms.

 :nodoc:
 **/
@frozen public enum ObjectiveCSupport
{
  /// Convert a `Results` to a `RLMResults`.
  public static func convert(object: Results<some Any>) -> RLMResults<AnyObject>
  {
    object.collection as! RLMResults<AnyObject>
  }

  /// Convert a `RLMResults` to a `Results`.
  public static func convert(object: RLMResults<AnyObject>) -> Results<Object>
  {
    Results(object)
  }

  /// Convert a `List` to a `RLMArray`.
  public static func convert(object: List<some Any>) -> RLMArray<AnyObject>
  {
    object.rlmArray
  }

  /// Convert a `MutableSet` to a `RLMSet`.
  public static func convert(object: MutableSet<some Any>) -> RLMSet<AnyObject>
  {
    object.rlmSet
  }

  /// Convert a `RLMArray` to a `List`.
  public static func convert(object: RLMArray<AnyObject>) -> List<Object>
  {
    List(collection: object)
  }

  /// Convert a `RLMSet` to a `MutableSet`.
  public static func convert(object: RLMSet<AnyObject>) -> MutableSet<Object>
  {
    MutableSet(collection: object)
  }

  /// Convert a `Map` to a `RLMDictionary`.
  public static func convert(object: Map<some Any, some Any>) -> RLMDictionary<AnyObject, AnyObject>
  {
    object.rlmDictionary
  }

  /// Convert a `RLMDictionary` to a `Map`.
  public static func convert<Key>(object: RLMDictionary<AnyObject, AnyObject>) -> Map<Key, Object>
  {
    Map(objc: object)
  }

  /// Convert a `LinkingObjects` to a `RLMResults`.
  public static func convert(object: LinkingObjects<some Any>) -> RLMResults<AnyObject>
  {
    object.collection as! RLMResults<AnyObject>
  }

  /// Convert a `RLMLinkingObjects` to a `Results`.
  public static func convert(object: RLMLinkingObjects<RLMObject>) -> Results<Object>
  {
    Results(object)
  }

  /// Convert a `Realm` to a `RLMRealm`.
  public static func convert(object: Realm) -> RLMRealm
  {
    object.rlmRealm
  }

  /// Convert a `RLMRealm` to a `Realm`.
  public static func convert(object: RLMRealm) -> Realm
  {
    Realm(object)
  }

  /// Convert a `Migration` to a `RLMMigration`.
  @available(*, deprecated, message: "This function is now redundant")
  public static func convert(object: Migration) -> RLMMigration
  {
    object
  }

  /// Convert a `ObjectSchema` to a `RLMObjectSchema`.
  public static func convert(object: ObjectSchema) -> RLMObjectSchema
  {
    object.rlmObjectSchema
  }

  /// Convert a `RLMObjectSchema` to a `ObjectSchema`.
  public static func convert(object: RLMObjectSchema) -> ObjectSchema
  {
    ObjectSchema(object)
  }

  /// Convert a `Property` to a `RLMProperty`.
  public static func convert(object: Property) -> RLMProperty
  {
    object.rlmProperty
  }

  /// Convert a `RLMProperty` to a `Property`.
  public static func convert(object: RLMProperty) -> Property
  {
    Property(object)
  }

  /// Convert a `Realm.Configuration` to a `RLMRealmConfiguration`.
  public static func convert(object: Realm.Configuration) -> RLMRealmConfiguration
  {
    object.rlmConfiguration
  }

  /// Convert a `RLMRealmConfiguration` to a `Realm.Configuration`.
  public static func convert(object: RLMRealmConfiguration) -> Realm.Configuration
  {
    .fromRLMRealmConfiguration(object)
  }

  /// Convert a `Schema` to a `RLMSchema`.
  public static func convert(object: Schema) -> RLMSchema
  {
    object.rlmSchema
  }

  /// Convert a `RLMSchema` to a `Schema`.
  public static func convert(object: RLMSchema) -> Schema
  {
    Schema(object)
  }

  /// Convert a `SortDescriptor` to a `RLMSortDescriptor`.
  public static func convert(object: SortDescriptor) -> RLMSortDescriptor
  {
    object.rlmSortDescriptorValue
  }

  /// Convert a `RLMSortDescriptor` to a `SortDescriptor`.
  public static func convert(object: RLMSortDescriptor) -> SortDescriptor
  {
    SortDescriptor(keyPath: object.keyPath, ascending: object.ascending)
  }

  /// Convert a `RLMShouldCompactOnLaunchBlock` to a Realm Swift compact block.
  @preconcurrency
  public static func convert(object: @escaping RLMShouldCompactOnLaunchBlock) -> @Sendable (Int, Int) -> Bool
  {
    { totalBytes, usedBytes in
      object(UInt(totalBytes), UInt(usedBytes))
    }
  }

  /// Convert a Realm Swift compact block to a `RLMShouldCompactOnLaunchBlock`.
  @preconcurrency
  public static func convert(object: @Sendable @escaping (Int, Int) -> Bool) -> RLMShouldCompactOnLaunchBlock
  {
    { totalBytes, usedBytes in
      object(Int(totalBytes), Int(usedBytes))
    }
  }

  /// Convert a RealmSwift before block to an RLMClientResetBeforeBlock
  @preconcurrency
  public static func convert(object: (@Sendable (Realm) -> Void)?) -> RLMClientResetBeforeBlock?
  {
    guard let object
    else
    {
      return nil
    }
    return
    { localRealm in
      object(Realm(localRealm))
    }
  }

  /// Convert an RLMClientResetBeforeBlock to a RealmSwift before  block
  @preconcurrency
  public static func convert(object: RLMClientResetBeforeBlock?) -> (@Sendable (Realm) -> Void)?
  {
    guard let object
    else
    {
      return nil
    }
    return
    { localRealm in
      object(localRealm.rlmRealm)
    }
  }

  /// Convert a RealmSwift after block to an RLMClientResetAfterBlock
  @preconcurrency
  public static func convert(object: (@Sendable (Realm, Realm) -> Void)?) -> RLMClientResetAfterBlock?
  {
    guard let object
    else
    {
      return nil
    }
    return
    { localRealm, remoteRealm in
      object(Realm(localRealm), Realm(remoteRealm))
    }
  }

  /// Convert an RLMClientResetAfterBlock to a RealmSwift after block
  @preconcurrency
  public static func convert(object: RLMClientResetAfterBlock?) -> (@Sendable (Realm, Realm) -> Void)?
  {
    guard let object
    else
    {
      return nil
    }
    return
    { localRealm, remoteRealm in
      object(localRealm.rlmRealm, remoteRealm.rlmRealm)
    }
  }

  /// Converts a swift block receiving a `SyncSubscriptionSet`to a RLMFlexibleSyncInitialSubscriptionsBlock receiving a `RLMSyncSubscriptionSet`.
  @preconcurrency
  public static func convert(block: @escaping @Sendable (SyncSubscriptionSet) -> Void) -> RLMFlexibleSyncInitialSubscriptionsBlock
  {
    { subscriptionSet in
      block(SyncSubscriptionSet(subscriptionSet))
    }
  }

  /// Converts a block receiving a `RLMSyncSubscriptionSet`to a swift block receiving a `SyncSubscriptionSet`.
  @preconcurrency
  public static func convert(block: RLMFlexibleSyncInitialSubscriptionsBlock?) -> (@Sendable (SyncSubscriptionSet) -> Void)?
  {
    guard let block
    else
    {
      return nil
    }
    return
    { subscriptionSet in
      block(subscriptionSet.rlmSyncSubscriptionSet)
    }
  }

  /// Converts a block receiving a `RLMSyncSubscriptionSet`to a swift block receiving a `SyncSubscriptionSet`.
  @preconcurrency
  public static func convert(block: @escaping RLMFlexibleSyncInitialSubscriptionsBlock) -> @Sendable (SyncSubscriptionSet) -> Void
  {
    { subscriptionSet in
      block(subscriptionSet.rlmSyncSubscriptionSet)
    }
  }
}
