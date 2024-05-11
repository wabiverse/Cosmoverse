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
import Realm.Private
import XCTest

#if canImport(RealmTestSupport)
  import RealmTestSupport
#endif

#if os(macOS)

  class InitLinkedToClass: RLMObject
  {
    @objc dynamic var value: SwiftRLMIntObject! = SwiftRLMIntObject(value: [0])
  }

  class SwiftRLMNonDefaultObject: RLMObject
  {
    @objc dynamic var value = 0
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class SwiftRLMLinkedNonDefaultObject: RLMObject
  {
    @objc dynamic var obj: SwiftRLMNonDefaultObject?
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class SwiftRLMNonDefaultArrayObject: RLMObject
  {
    @objc dynamic var array = RLMArray<SwiftRLMNonDefaultObject>(objectClassName: SwiftRLMNonDefaultObject.className())
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class SwiftRLMNonDefaultSetObject: RLMObject
  {
    @objc dynamic var set = RLMSet<SwiftRLMNonDefaultObject>(objectClassName: SwiftRLMNonDefaultObject.className())
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class SwiftRLMNonDefaultDictionaryObject: RLMObject
  {
    @objc dynamic var dictionary = RLMDictionary<NSString, SwiftRLMNonDefaultObject>(objectClassName: SwiftRLMNonDefaultObject.className(), keyType: .string)
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class SwiftRLMMutualLink1Object: RLMObject
  {
    @objc dynamic var object: SwiftRLMMutualLink2Object?
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class SwiftRLMMutualLink2Object: RLMObject
  {
    @objc dynamic var object: SwiftRLMMutualLink1Object?
    override public class func shouldIncludeInDefaultSchema() -> Bool
    {
      false
    }
  }

  class IgnoredLinkPropertyObject: RLMObject
  {
    @objc dynamic var value = 0
    var obj = SwiftRLMIntObject()

    override class func ignoredProperties() -> [String]
    {
      ["obj"]
    }
  }

  @MainActor
  class SwiftRLMRecursingSchemaTestObject: RLMObject
  {
    @objc dynamic var propertyWithIllegalDefaultValue: SwiftRLMIntObject? = {
      if mayAccessSchema
      {
        let realm = RLMRealm.default()
        return SwiftRLMIntObject.allObjects().firstObject() as! SwiftRLMIntObject?
      }
      return nil
    }()

    static var mayAccessSchema = false
  }

  class InvalidArrayType: FakeObject
  {
    @objc dynamic var array = RLMArray<SwiftRLMIntObject>(objectClassName: "invalid class")
  }

  class InvalidSetType: FakeObject
  {
    @objc dynamic var set = RLMSet<SwiftRLMIntObject>(objectClassName: "invalid class")
  }

  class InvalidDictionaryType: FakeObject
  {
    @objc dynamic var dictionary = RLMDictionary<NSString, SwiftRLMIntObject>(objectClassName: "invalid class", keyType: .string)
  }

  @MainActor
  class InitAppendsToArrayProperty: RLMObject
  {
    @objc dynamic var propertyWithIllegalDefaultValue: RLMArray<InitAppendsToArrayProperty> = {
      if mayAppend
      {
        mayAppend = false
        let array = RLMArray<InitAppendsToArrayProperty>(objectClassName: InitAppendsToArrayProperty.className())
        array.add(InitAppendsToArrayProperty())
        return array
      }
      return RLMArray<InitAppendsToArrayProperty>(objectClassName: InitAppendsToArrayProperty.className())
    }()

    static var mayAppend = false
  }

  class NoProps: FakeObject
  {
    // no @objc properties
  }

  class OnlyComputedSource: RLMObject
  {
    @objc dynamic var link: OnlyComputedTarget?
  }

  class OnlyComputedTarget: RLMObject
  {
    @objc dynamic var backlinks: RLMLinkingObjects<OnlyComputedSource>?

    override class func linkingObjectsProperties() -> [String: RLMPropertyDescriptor]
    {
      ["backlinks": RLMPropertyDescriptor(with: OnlyComputedSource.self, propertyName: "link")]
    }
  }

  class OnlyComputedNoBacklinksProps: FakeObject
  {
    var computedProperty: String
    {
      "Test_String"
    }
  }

  @MainActor
  class RequiresObjcName: RLMObject
  {
    static var enable = false
    @MainActor
    override class func _realmIgnoreClass() -> Bool
    {
      !enable
    }
  }

  enum ClassWrappingObjectSubclass
  {
    class Inner: RequiresObjcName
    {
      @objc dynamic var value = 0
    }
  }

  enum StructWrappingObjectSubclass
  {
    class Inner: RequiresObjcName
    {
      @objc dynamic var value = 0
    }
  }

  enum EnumWrappingObjectSubclass
  {
    class Inner: RequiresObjcName
    {
      @objc dynamic var value = 0
    }
  }

  private class PrivateClassWithoutExplicitObjcName: RequiresObjcName
  {
    @objc dynamic var value = 0
  }

  class SwiftRLMSchemaTests: RLMMultiProcessTestCase
  {
    func testWorksAtAll()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
      }
    }

    func testShouldRaiseObjectWithoutProperties()
    {
      assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: NoProps.self),
                                     "No properties are defined for 'NoProps'. Did you remember to mark them with '@objc' or '@Persisted' in your model?")
    }

    func testShouldNotThrowForObjectWithOnlyBacklinksProps()
    {
      let config = RLMRealmConfiguration.default()
      config.objectClasses = [OnlyComputedTarget.self, OnlyComputedSource.self]
      config.inMemoryIdentifier = #function
      let r = try! RLMRealm(configuration: config)
      try! r.transaction
      {
        _ = OnlyComputedTarget.create(in: r, withValue: [])
      }

      let schema = OnlyComputedTarget().objectSchema
      XCTAssertEqual(schema.computedProperties.count, 1)
      XCTAssertEqual(schema.properties.count, 0)
    }

    func testShouldThrowForObjectWithOnlyComputedNoBacklinksProps()
    {
      assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: OnlyComputedNoBacklinksProps.self),
                                     "No properties are defined for 'OnlyComputedNoBacklinksProps'. Did you remember to mark them with '@objc' or '@Persisted' in your model?")
    }

    func testSchemaInitWithLinkedToObjectUsingInitWithValue()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      let config = RLMRealmConfiguration.default()
      config.objectClasses = [IgnoredLinkPropertyObject.self]
      config.inMemoryIdentifier = #function
      let r = try! RLMRealm(configuration: config)
      try! r.transaction
      {
        _ = IgnoredLinkPropertyObject.create(in: r, withValue: [1])
      }
    }

    func testCreateUnmanagedObjectWithUninitializedSchema()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      // Object in default schema
      _ = SwiftRLMIntObject()
      // Object not in default schema
      _ = SwiftRLMNonDefaultObject()
    }

    func testCreateUnmanagedObjectWithNestedObjectWithUninitializedSchema()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      // Objects in default schema

      // Should not throw (or crash) despite creating an object with an
      // uninitialized schema during schema init
      _ = InitLinkedToClass()
      // Again with an object that links to an uninitialized type
      // rather than creating one
      _ = SwiftRLMCompanyObject()

      // Objects not in default schema
      _ = SwiftRLMLinkedNonDefaultObject(value: [[1]])
      _ = SwiftRLMNonDefaultArrayObject(value: [[[1]]])
      _ = SwiftRLMNonDefaultSetObject(value: [[[1]]])
      _ = SwiftRLMMutualLink1Object()
    }

    func testCreateUnmanagedObjectWhichCreatesAnotherClassViaInitWithValueDuringSchemaInit()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      _ = InitLinkedToClass(value: [[0]])
      _ = SwiftRLMCompanyObject(value: [[["Jaden", 20, false] as [Any]]])
    }

    func testInitUnmanagedObjectNotInClassSubsetDuringSchemaInit()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      let config = RLMRealmConfiguration.default()
      config.objectClasses = [IgnoredLinkPropertyObject.self]
      config.inMemoryIdentifier = #function
      _ = try! RLMRealm(configuration: config)
      let r = try! RLMRealm(configuration: RLMRealmConfiguration.default())
      try! r.transaction
      {
        _ = IgnoredLinkPropertyObject.create(in: r, withValue: [1])
      }
    }

    @MainActor
    func testPreventsDeadLocks()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      SwiftRLMRecursingSchemaTestObject.mayAccessSchema = true
      assertThrowsWithReasonMatching(RLMSchema.shared(), ".*recursive.*")
    }

    @MainActor
    func testAccessSchemaCreatesObjectWhichAttempsInsertionsToArrayProperty()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      // This is different from the above tests in that it is a to-many link
      // and it only occurs while the schema is initializing
      InitAppendsToArrayProperty.mayAppend = true
      assertThrowsWithReasonMatching(RLMSchema.shared(),
                                     ".*Object cannot be inserted unless the schema is initialized.*")
    }

    func testInvalidObjectTypeForRLMArray()
    {
      assertThrowsWithReasonMatching(RLMObjectSchema(forObjectClass: InvalidArrayType.self),
                                     "RLMArray\\<invalid class\\>")
    }

    @MainActor
    func testInvalidNestedClass()
    {
      if isParent
      {
        XCTAssertEqual(0, runChildAndWait(), "Tests in child process failed")
        return
      }

      RequiresObjcName.enable = true
      assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: ClassWrappingObjectSubclass.Inner.self),
                                     "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
      assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: StructWrappingObjectSubclass.Inner.self),
                                     "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
      assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: EnumWrappingObjectSubclass.Inner.self),
                                     "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
      assertThrowsWithReasonMatching(RLMSchema.sharedSchema(for: PrivateClassWithoutExplicitObjcName.self),
                                     "Object subclass '.*' must explicitly set the class's objective-c name with @objc\\(ClassName\\) because it is not a top-level public class.")
    }
  }

#endif
