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

#if os(macOS)

  import Combine
  import RealmSwift
  import XCTest

  #if canImport(RealmTestSupport)
    import RealmSwiftTestSupport
    import RealmSyncTestSupport
    import RealmTestSupport
  #endif

  public func randomString(_ length: Int) -> String
  {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0 ..< length).map { _ in letters.randomElement()! })
  }

  public typealias ChildProcessEnvironment = RLMChildProcessEnvironment

  public enum ProcessKind
  {
    case parent
    case child(environment: ChildProcessEnvironment)

    public static var current: ProcessKind
    {
      if getenv("RLMProcessIsChild") == nil
      {
        .parent
      }
      else
      {
        .child(environment: ChildProcessEnvironment.current())
      }
    }
  }

  /// SwiftSyncTestCase wraps RLMSyncTestCase to make it more pleasant to use from
  /// Swift. Most of the comments there apply to this as well.
  @available(macOS 13, *)
  @MainActor
  open class SwiftSyncTestCase: RLMSyncTestCase
  {
    /// overridden in subclasses to generate a FLX config instead of a PBS one
    open func configuration(user: User) -> Realm.Configuration
    {
      user.configuration(partitionValue: name)
    }

    /// Must be overriden in each subclass to specify which types will be used
    /// in this test case.
    open var objectTypes: [ObjectBase.Type]
    {
      [SwiftPerson.self]
    }

    override open func defaultObjectTypes() -> [AnyClass]
    {
      objectTypes
    }

    public func executeChild(file: StaticString = #file, line: UInt = #line)
    {
      XCTAssert(runChildAndWait() == 0, "Tests in child process failed", file: file, line: line)
    }

    public func basicCredentials(usernameSuffix: String = "", app: App? = nil) -> Credentials
    {
      let email = "\(randomString(10))\(usernameSuffix)"
      let password = "abcdef"
      let credentials = Credentials.emailPassword(email: email, password: password)
      let ex = expectation(description: "Should register in the user properly")
      (app ?? self.app).emailPasswordAuth.registerUser(email: email, password: password, completion: { error in
        XCTAssertNil(error)
        ex.fulfill()
      })
      wait(for: [ex], timeout: 4)
      return credentials
    }

    public func openRealm(app: App? = nil, wait: Bool = true) throws -> Realm
    {
      let realm = try Realm(configuration: configuration(app: app))
      if wait
      {
        waitForDownloads(for: realm)
      }
      return realm
    }

    public func configuration(app: App? = nil) throws -> Realm.Configuration
    {
      let user = try createUser(app: app)
      var config = configuration(user: user)
      config.objectTypes = objectTypes
      return config
    }

    public func openRealm(configuration: Realm.Configuration) throws -> Realm
    {
      Realm.asyncOpen(configuration: configuration).await(self)
    }

    public func openRealm(user: User, partitionValue: String) throws -> Realm
    {
      var config = user.configuration(partitionValue: partitionValue)
      config.objectTypes = objectTypes
      return try openRealm(configuration: config)
    }

    public func createUser(app: App? = nil) throws -> User
    {
      let app = app ?? self.app
      return try logInUser(for: basicCredentials(app: app), app: app)
    }

    public func logInUser(for credentials: Credentials, app: App? = nil) throws -> User
    {
      let user = (app ?? self.app).login(credentials: credentials).await(self, timeout: 60.0)
      XCTAssertTrue(user.isLoggedIn)
      return user
    }

    public func waitForUploads(for realm: Realm)
    {
      waitForUploads(for: ObjectiveCSupport.convert(object: realm))
    }

    public func waitForDownloads(for realm: Realm)
    {
      waitForDownloads(for: ObjectiveCSupport.convert(object: realm))
    }

    /// Populate the server-side data using the given block, which is called in
    /// a write transaction. Note that unlike the obj-c versions, this works for
    /// both PBS and FLX sync.
    public func write(app: App? = nil, _ block: (Realm) throws -> Void) throws
    {
      try autoreleasepool
      {
        let realm = try openRealm(app: app)
        RLMRealmSubscribeToAll(ObjectiveCSupport.convert(object: realm))

        try realm.write
        {
          try block(realm)
        }
        waitForUploads(for: realm)

        let syncSession = try XCTUnwrap(realm.syncSession)
        syncSession.suspend()
        syncSession.parentUser()?.remove().await(self)
      }
    }

    public func checkCount(expected: Int,
                           _ realm: Realm,
                           _ type: (some Object).Type,
                           file: StaticString = #file,
                           line: UInt = #line)
    {
      realm.refresh()
      let actual = realm.objects(type).count
      XCTAssertEqual(actual, expected,
                     "Error: expected \(expected) items, but got \(actual) (process: \(isParent ? "parent" : "child"))",
                     file: file,
                     line: line)
    }

    var exceptionThrown = false

    public func assertThrows(_ block: @autoclosure () -> some Any, named: String? = RLMExceptionName,
                             _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
    {
      exceptionThrown = true
      RLMAssertThrowsWithName(self, { _ = block() }, named, message, fileName, lineNumber)
    }

    public func assertThrows(_ block: @autoclosure () -> some Any, reason: String,
                             _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
    {
      exceptionThrown = true
      RLMAssertThrowsWithReason(self, { _ = block() }, reason, message, fileName, lineNumber)
    }

    public func assertThrows(_ block: @autoclosure () -> some Any, reasonMatching regexString: String,
                             _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
    {
      exceptionThrown = true
      RLMAssertThrowsWithReasonMatching(self, { _ = block() }, regexString, message, fileName, lineNumber)
    }

    public static let bigObjectCount = 2
    public func populateRealm() throws
    {
      try write
      { realm in
        for _ in 0 ..< SwiftSyncTestCase.bigObjectCount
        {
          realm.add(SwiftHugeSyncObject.create(key: name))
        }
      }
    }

    // MARK: - Mongo Client

    public func setupMongoCollection(for type: ObjectBase.Type) throws -> MongoCollection
    {
      let collection = anonymousUser.collection(for: type, app: app)
      removeAllFromCollection(collection)
      return collection
    }

    public func removeAllFromCollection(_ collection: MongoCollection)
    {
      let deleteEx = expectation(description: "Delete all from Mongo collection")
      collection.deleteManyDocuments(filter: [:])
      { result in
        if case .failure = result
        {
          XCTFail("Should delete")
        }
        deleteEx.fulfill()
      }
      wait(for: [deleteEx], timeout: 30.0)
    }

    public func waitForCollectionCount(_ collection: MongoCollection, _ count: Int)
    {
      let waitStart = Date()
      while collection.count(filter: [:]).await(self) < count, waitStart.timeIntervalSinceNow > -600.0
      {
        sleep(1)
      }
      XCTAssertEqual(collection.count(filter: [:]).await(self), count)
    }

    // MARK: - Async helpers

    /// These are async versions of the synchronous functions defined above.
    /// They should function identially other than being async rather than using
    /// expecatations to synchronously await things.
    public func basicCredentials(usernameSuffix: String = "", app: App? = nil) async throws -> Credentials
    {
      let email = "\(randomString(10))\(usernameSuffix)"
      let password = "abcdef"
      let credentials = Credentials.emailPassword(email: email, password: password)
      try await (app ?? self.app).emailPasswordAuth.registerUser(email: email, password: password)
      return credentials
    }

    @MainActor
    @nonobjc public func openRealm() async throws -> Realm
    {
      try await Realm(configuration: configuration(), downloadBeforeOpen: .always)
    }

    @MainActor
    public func write(_ block: @escaping (Realm) throws -> Void) async throws
    {
      try await Task
      {
        let realm = try await openRealm()
        try await realm.asyncWrite
        {
          try block(realm)
        }
        let syncSession = try XCTUnwrap(realm.syncSession)
        try await syncSession.wait(for: .upload)
        syncSession.suspend()
        try await syncSession.parentUser()?.remove()
      }.value
    }

    public func createUser(app: App? = nil) async throws -> User
    {
      let credentials = try await basicCredentials(app: app)
      return try await (app ?? self.app).login(credentials: credentials)
    }
  }

  @available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *)
  public extension Publisher
  {
    func expectValue(_: XCTestCase, _ expectation: XCTestExpectation,
                     receiveValue: (@Sendable (Self.Output) -> Void)? = nil) -> AnyCancellable
    {
      sink(receiveCompletion: { result in
        if case let .failure(error) = result
        {
          XCTFail("Unexpected failure: \(error)")
        }
      }, receiveValue: { value in
        receiveValue?(value)
        expectation.fulfill()
      })
    }

    /// Synchronously await non-error completion of the publisher, calling the
    /// `receiveValue` callback with the value if supplied.
    @MainActor
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0, receiveValue: (@Sendable (Self.Output) -> Void)? = nil)
    {
      let expectation = testCase.expectation(description: "Async combine pipeline")
      let cancellable = expectValue(testCase, expectation, receiveValue: receiveValue)
      testCase.wait(for: [expectation], timeout: timeout)
      cancellable.cancel()
    }

    /// Synchronously await non-error completion of the publisher, returning the published value.
    @discardableResult
    @MainActor
    func await(_ testCase: XCTestCase, timeout: TimeInterval = 20.0) -> Self.Output
    {
      let expectation = testCase.expectation(description: "Async combine pipeline")
      let value = Locked(Self.Output?.none)
      let cancellable = expectValue(testCase, expectation, receiveValue: { value.wrappedValue = $0 })
      testCase.wait(for: [expectation], timeout: timeout)
      cancellable.cancel()
      return value.wrappedValue!
    }

    /// Synchrously await error completion of the publisher
    @MainActor
    func awaitFailure(_ testCase: XCTestCase, timeout: TimeInterval = 20.0,
                      _ errorHandler: (@Sendable (Self.Failure) -> Void)? = nil)
    {
      let expectation = testCase.expectation(description: "Async combine pipeline should fail")
      let cancellable = sink(receiveCompletion: { @Sendable result in
        if case let .failure(error) = result
        {
          errorHandler?(error)
          expectation.fulfill()
        }
      }, receiveValue: { @Sendable value in
        XCTFail("Should have failed but got \(value)")
      })
      testCase.wait(for: [expectation], timeout: timeout)
      cancellable.cancel()
    }

    @MainActor
    func awaitFailure<E: Error>(_ testCase: XCTestCase, timeout: TimeInterval = 20.0,
                                _ errorHandler: @escaping (@Sendable (E) -> Void))
    {
      awaitFailure(testCase, timeout: timeout)
      { error in
        guard let error = error as? E
        else
        {
          XCTFail("Expected error of type \(E.self), got \(error)")
          return
        }
        errorHandler(error)
      }
    }
  }

#endif // os(macOS)
