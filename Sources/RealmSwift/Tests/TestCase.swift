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
import Realm.Dynamic
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
  import RealmSwiftTestSupport
  import RealmTestSupport
#endif

func inMemoryRealm(_ inMememoryIdentifier: String) -> Realm
{
  try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: inMememoryIdentifier))
}

class TestCase: RLMTestCaseBase, @unchecked Sendable
{
  @Locked var exceptionThrown = false
  var testDir: String!

  let queue = DispatchQueue(label: "background")

  @discardableResult
  func realmWithTestPath(configuration: Realm.Configuration = Realm.Configuration()) -> Realm
  {
    var configuration = configuration
    configuration.fileURL = testRealmURL()
    return try! Realm(configuration: configuration)
  }

  override class func tearDown()
  {
    RLMRealm.resetRealmState()
    super.tearDown()
  }

  override func invokeTest()
  {
    testDir = RLMRealmPathForFile(realmFilePrefix())

    do
    {
      try FileManager.default.removeItem(atPath: testDir)
    }
    catch
    {
      // The directory shouldn't actually already exist, so not an error
    }
    try! FileManager.default.createDirectory(at: URL(fileURLWithPath: testDir, isDirectory: true),
                                             withIntermediateDirectories: true, attributes: nil)

    let config = Realm.Configuration(fileURL: defaultRealmURL())
    Realm.Configuration.defaultConfiguration = config

    exceptionThrown = false
    autoreleasepool { super.invokeTest() }
    queue.sync {}

    if !exceptionThrown
    {
      XCTAssertFalse(RLMHasCachedRealmForPath(defaultRealmURL().path))
      XCTAssertFalse(RLMHasCachedRealmForPath(testRealmURL().path))
    }

    resetRealmState()

    do
    {
      try FileManager.default.removeItem(atPath: testDir)
    }
    catch
    {
      XCTFail("Unable to delete realm files")
    }

    // Verify that there are no remaining realm files after the test
    let parentDir = (testDir as NSString).deletingLastPathComponent
    for url in FileManager.default.enumerator(atPath: parentDir)!
    {
      let url = url as! NSString
      XCTAssertNotEqual(url.pathExtension, "realm", "Lingering realm file at \(parentDir)/\(url)")
      assert(url.pathExtension != "realm")
    }
  }

  func dispatchSyncNewThread(block: @escaping () -> Void)
  {
    queue.async
    {
      autoreleasepool
      {
        block()
      }
    }
    queue.sync {}
  }

  func assertThrows(_ block: @autoclosure () -> some Any, named: String? = RLMExceptionName,
                    _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
  {
    exceptionThrown = true
    RLMAssertThrowsWithName(self, { _ = block() }, named, message, fileName, lineNumber)
  }

  func assertThrows(_ block: @autoclosure () -> some Any, reason: String,
                    _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
  {
    exceptionThrown = true
    RLMAssertThrowsWithReason(self, { _ = block() }, reason, message, fileName, lineNumber)
  }

  func assertThrows(_ block: @autoclosure () -> some Any, reasonMatching regexString: String,
                    _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
  {
    exceptionThrown = true
    RLMAssertThrowsWithReasonMatching(self, { _ = block() }, regexString, message, fileName, lineNumber)
  }

  private func realmFilePrefix() -> String
  {
    let name: String? = name
    return name!.trimmingCharacters(in: CharacterSet(charactersIn: "-[]"))
  }

  func testRealmURL() -> URL
  {
    realmURLForFile("test.realm")
  }

  func defaultRealmURL() -> URL
  {
    realmURLForFile("default.realm")
  }

  private func realmURLForFile(_ fileName: String) -> URL
  {
    let directory = URL(fileURLWithPath: testDir, isDirectory: true)
    return directory.appendingPathComponent(fileName, isDirectory: false)
  }
}

public extension Realm
{
  @discardableResult
  func create<T: Object>(_ type: T.Type, value: [String: Any], update: UpdatePolicy = .error) -> T
  {
    create(type, value: value as Any, update: update)
  }

  @discardableResult
  func create<T: Object>(_ type: T.Type, value: [Any], update: UpdatePolicy = .error) -> T
  {
    create(type, value: value as Any, update: update)
  }
}

public extension Object
{
  convenience init(value: [String: Any])
  {
    self.init(value: value as Any)
  }

  convenience init(value: [Any])
  {
    self.init(value: value as Any)
  }
}

public extension AsymmetricObject
{
  convenience init(value: [String: Any])
  {
    self.init(value: value as Any)
  }

  convenience init(value: [Any])
  {
    self.init(value: value as Any)
  }
}
