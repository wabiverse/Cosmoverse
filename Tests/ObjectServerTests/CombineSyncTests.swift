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
  import Realm
  import Realm.Private
  import RealmSwift
  import XCTest

  #if canImport(RealmTestSupport)
    import RealmSwiftSyncTestSupport
    import RealmSwiftTestSupport
    import RealmSyncTestSupport
    import RealmTestSupport
  #endif

  @available(macOS 13, *)
  @objc(CombineSyncTests)
  class CombineSyncTests: SwiftSyncTestCase
  {
    override var objectTypes: [ObjectBase.Type]
    {
      [Dog.self, SwiftPerson.self, SwiftHugeSyncObject.self]
    }

    var subscriptions: Set<AnyCancellable> = []
    override func tearDown()
    {
      subscriptions.forEach { $0.cancel() }
      subscriptions = []
      super.tearDown()
    }

    // swiftlint:disable multiple_closures_with_trailing_closure
    func testWatchCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]

      let watchEx1 = Locked(expectation(description: "Main thread watch"))
      let watchEx2 = Locked(expectation(description: "Background thread watch"))

      collection.watch()
        .onOpen
        {
          watchEx1.wrappedValue.fulfill()
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.global())
        .sink(receiveCompletion: { @Sendable _ in })
        { @Sendable _ in
          XCTAssertFalse(Thread.isMainThread)
          watchEx1.wrappedValue.fulfill()
        }.store(in: &subscriptions)

      collection.watch()
        .onOpen
        {
          watchEx2.wrappedValue.fulfill()
        }
        .subscribe(on: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in })
        { _ in
          XCTAssertTrue(Thread.isMainThread)
          watchEx2.wrappedValue.fulfill()
        }.store(in: &subscriptions)

      for _ in 0 ..< 3
      {
        wait(for: [watchEx1.wrappedValue, watchEx2.wrappedValue], timeout: 60.0)
        watchEx1.wrappedValue = expectation(description: "Main thread watch")
        watchEx2.wrappedValue = expectation(description: "Background thread watch")
        collection.insertOne(document)
        { result in
          if case let .failure(error) = result
          {
            XCTFail("Failed to insert: \(error)")
          }
        }
      }
      wait(for: [watchEx1.wrappedValue, watchEx2.wrappedValue], timeout: 60.0)
    }

    func testWatchCombineWithFilterIds() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]
      let document3: Document = ["name": "john", "breed": "cane corso"]
      let document4: Document = ["name": "ted", "breed": "bullmastiff"]

      let objIds = collection.insertMany([document, document2, document3, document4]).await(self)
      let objectIds = objIds.map { $0.objectIdValue! }

      let watchEx1 = Locked(expectation(description: "Main thread watch"))
      let watchEx2 = Locked(expectation(description: "Background thread watch"))
      collection.watch(filterIds: [objectIds[0]])
        .onOpen
        {
          watchEx1.wrappedValue.fulfill()
        }
        .subscribe(on: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in })
        { changeEvent in
          XCTAssertTrue(Thread.isMainThread)
          guard let doc = changeEvent.documentValue
          else
          {
            return
          }

          let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
          if objectId == objectIds[0]
          {
            watchEx1.wrappedValue.fulfill()
          }
        }.store(in: &subscriptions)

      collection.watch(filterIds: [objectIds[1]])
        .onOpen
        {
          watchEx2.wrappedValue.fulfill()
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.global())
        .sink(receiveCompletion: { _ in })
        { @Sendable changeEvent in
          XCTAssertFalse(Thread.isMainThread)
          guard let doc = changeEvent.documentValue
          else
          {
            return
          }

          let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
          if objectId == objectIds[1]
          {
            watchEx2.wrappedValue.fulfill()
          }
        }.store(in: &subscriptions)

      for i in 0 ..< 3
      {
        wait(for: [watchEx1.wrappedValue, watchEx2.wrappedValue], timeout: 60.0)
        watchEx1.wrappedValue = expectation(description: "Main thread watch")
        watchEx2.wrappedValue = expectation(description: "Background thread watch")

        let name: AnyBSON = .string("fido-\(i)")
        collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                     update: ["name": name, "breed": "king charles"])
        { result in
          if case let .failure(error) = result
          {
            XCTFail("Failed to update: \(error)")
          }
        }
        collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                     update: ["name": name, "breed": "king charles"])
        { result in
          if case let .failure(error) = result
          {
            XCTFail("Failed to update: \(error)")
          }
        }
      }
      wait(for: [watchEx1.wrappedValue, watchEx2.wrappedValue], timeout: 60.0)
    }

    func testWatchCombineWithMatchFilter() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]
      let document3: Document = ["name": "john", "breed": "cane corso"]
      let document4: Document = ["name": "ted", "breed": "bullmastiff"]

      let objIds = collection.insertMany([document, document2, document3, document4]).await(self)
      XCTAssertEqual(objIds.count, 4)
      let objectIds = objIds.map { $0.objectIdValue! }

      let watchEx1 = Locked(expectation(description: "Main thread watch"))
      let watchEx2 = Locked(expectation(description: "Background thread watch"))
      collection.watch(matchFilter: ["fullDocument._id": AnyBSON.objectId(objectIds[0])])
        .onOpen
        {
          watchEx1.wrappedValue.fulfill()
        }
        .subscribe(on: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in })
        { changeEvent in
          XCTAssertTrue(Thread.isMainThread)
          guard let doc = changeEvent.documentValue
          else
          {
            return
          }

          let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
          if objectId == objectIds[0]
          {
            watchEx1.wrappedValue.fulfill()
          }
        }.store(in: &subscriptions)

      collection.watch(matchFilter: ["fullDocument._id": AnyBSON.objectId(objectIds[1])])
        .onOpen
        {
          watchEx2.wrappedValue.fulfill()
        }
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.global())
        .sink(receiveCompletion: { _ in })
        { @Sendable changeEvent in
          XCTAssertFalse(Thread.isMainThread)
          guard let doc = changeEvent.documentValue
          else
          {
            return
          }

          let objectId = doc["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
          if objectId == objectIds[1]
          {
            watchEx2.wrappedValue.fulfill()
          }
        }.store(in: &subscriptions)

      for i in 0 ..< 3
      {
        wait(for: [watchEx1.wrappedValue, watchEx2.wrappedValue], timeout: 60.0)
        watchEx1.wrappedValue = expectation(description: "Main thread watch")
        watchEx2.wrappedValue = expectation(description: "Background thread watch")

        let name: AnyBSON = .string("fido-\(i)")
        collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[0])],
                                     update: ["name": name, "breed": "king charles"])
        { result in
          if case let .failure(error) = result
          {
            XCTFail("Failed to update: \(error)")
          }
        }
        collection.updateOneDocument(filter: ["_id": AnyBSON.objectId(objectIds[1])],
                                     update: ["name": name, "breed": "king charles"])
        { result in
          if case let .failure(error) = result
          {
            XCTFail("Failed to update: \(error)")
          }
        }
      }
      wait(for: [watchEx1.wrappedValue, watchEx2.wrappedValue], timeout: 60.0)
    }

    // MARK: - Combine promises

    func testAppLoginCombine()
    {
      let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
      let password = randomString(10)

      let loginEx = expectation(description: "Login user")
      let appEx = expectation(description: "App changes triggered")
      var triggered = 0
      app.objectWillChange.sink
      { _ in
        triggered += 1
        if triggered == 2
        {
          appEx.fulfill()
        }
      }.store(in: &subscriptions)

      app.emailPasswordAuth.registerUser(email: email, password: password)
        .flatMap { @Sendable in self.app.login(credentials: .emailPassword(email: email, password: password)) }
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { result in
          if case let .failure(error) = result
          {
            XCTFail("Should have completed login chain: \(error.localizedDescription)")
          }
        }, receiveValue: { user in
          user.objectWillChange.sink
          { @Sendable user in
            XCTAssert(!user.isLoggedIn)
            loginEx.fulfill()
          }.store(in: &self.subscriptions)
          XCTAssertEqual(user.id, self.app.currentUser?.id)
          user.logOut { _ in } // logout user and make sure it is observed
        })
        .store(in: &subscriptions)
      wait(for: [loginEx, appEx], timeout: 30.0)
      XCTAssertEqual(app.allUsers.count, 1)
      XCTAssertEqual(triggered, 2)
    }

    func testAsyncOpenCombine()
    {
      let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
      let password = randomString(10)
      app.emailPasswordAuth.registerUser(email: email, password: password)
        .flatMap { @Sendable in self.app.login(credentials: .emailPassword(email: email, password: password)) }
        .flatMap
        { @Sendable (user: User) in
          var config = user.configuration(partitionValue: self.name)
          config.objectTypes = [SwiftHugeSyncObject.self]
          return Realm.asyncOpen(configuration: config)
        }
        .tryMap
        { realm in
          try realm.write
          {
            realm.add(SwiftHugeSyncObject.create())
            realm.add(SwiftHugeSyncObject.create())
          }
          let progressEx = self.expectation(description: "Should upload")
          let token = try XCTUnwrap(realm.syncSession).addProgressNotification(for: .upload, mode: .forCurrentlyOutstandingWork)
          {
            if $0.isTransferComplete
            {
              progressEx.fulfill()
            }
          }
          self.wait(for: [progressEx], timeout: 30.0)
          token?.invalidate()
        }
        .await(self, timeout: 30.0)

      let chainEx = expectation(description: "Should chain realm login => realm async open")
      let progressEx = expectation(description: "Should receive progress notification")
      app.login(credentials: .anonymous)
        .flatMap
        { @Sendable user in
          var config = user.configuration(partitionValue: self.name)
          config.objectTypes = [SwiftHugeSyncObject.self]
          return Realm.asyncOpen(configuration: config).onProgressNotification
          {
            if $0.isTransferComplete
            {
              progressEx.fulfill()
            }
          }
        }
        .expectValue(self, chainEx)
        { realm in
          XCTAssertEqual(realm.objects(SwiftHugeSyncObject.self).count, 2)
        }.store(in: &subscriptions)
      wait(for: [chainEx, progressEx], timeout: 30.0)
    }

    func testAsyncOpenStandaloneCombine() throws
    {
      try autoreleasepool
      {
        let realm = try Realm()
        try realm.write
        {
          (0 ..< 10000).forEach { _ in realm.add(SwiftPerson(firstName: "Charlie", lastName: "Bucket")) }
        }
      }

      Realm.asyncOpen().await(self)
      { realm in
        XCTAssertEqual(realm.objects(SwiftPerson.self).count, 10000)
      }
    }

    func testDeleteUserCombine()
    {
      let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
      let password = randomString(10)

      let appEx = expectation(description: "App changes triggered")
      var triggered = 0
      app.objectWillChange.sink
      { _ in
        triggered += 1
        if triggered == 2
        {
          appEx.fulfill()
        }
      }.store(in: &subscriptions)

      app.emailPasswordAuth.registerUser(email: email, password: password)
        .flatMap { @Sendable in self.app.login(credentials: .emailPassword(email: email, password: password)) }
        .flatMap { @Sendable in $0.delete() }
        .await(self)
      wait(for: [appEx], timeout: 30.0)
      XCTAssertEqual(app.allUsers.count, 0)
      XCTAssertEqual(triggered, 2)
    }

    func testMongoCollectionInsertCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]

      collection.insertOne(document).await(self)
      collection.insertMany([document, document2])
        .await(self)
        { objectIds in
          XCTAssertEqual(objectIds.count, 2)
        }
      collection.find(filter: [:])
        .await(self)
        { findResult in
          XCTAssertEqual(findResult.map { $0["name"]??.stringValue }, ["fido", "fido", "rex"])
        }
    }

    func testMongoCollectionFindCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "tibetan mastiff"]
      let document3: Document = ["name": "rex", "breed": "tibetan mastiff", "coat": ["fawn", "brown", "white"]]
      let findOptions = FindOptions(1, nil)

      collection.find(filter: [:], options: findOptions)
        .await(self)
        { findResult in
          XCTAssertEqual(findResult.count, 0)
        }
      collection.insertMany([document, document2, document3]).await(self)
      collection.find(filter: [:])
        .await(self)
        { findResult in
          XCTAssertEqual(findResult.map { $0["name"]??.stringValue }, ["fido", "rex", "rex"])
        }
      collection.find(filter: [:], options: findOptions)
        .await(self)
        { findResult in
          XCTAssertEqual(findResult.count, 1)
          XCTAssertEqual(findResult[0]["name"]??.stringValue, "fido")
        }
      collection.find(filter: document3, options: findOptions)
        .await(self)
        { findResult in
          XCTAssertEqual(findResult.count, 1)
        }
      collection.findOneDocument(filter: document).await(self)

      collection.findOneDocument(filter: document, options: findOptions).await(self)
    }

    func testMongoCollectionCountAndAggregateCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]

      collection.insertMany([document]).await(self)
      collection.aggregate(pipeline: [["$match": ["name": "fido"]], ["$group": ["_id": "$name"]]])
        .await(self)
      collection.count(filter: document).await(self)
      { count in
        XCTAssertEqual(count, 1)
      }
      collection.count(filter: document, limit: 1).await(self)
      { count in
        XCTAssertEqual(count, 1)
      }
    }

    func testMongoCollectionDeleteOneCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]

      collection.deleteOneDocument(filter: document).await(self)
      { count in
        XCTAssertEqual(count, 0)
      }
      collection.insertMany([document, document2]).await(self)
      collection.deleteOneDocument(filter: document).await(self)
      { count in
        XCTAssertEqual(count, 1)
      }
    }

    func testMongoCollectionDeleteManyCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]

      collection.deleteManyDocuments(filter: document).await(self)
      { count in
        XCTAssertEqual(count, 0)
      }
      collection.insertMany([document, document2]).await(self)
      collection.deleteManyDocuments(filter: ["breed": "cane corso"]).await(self)
      { count in
        XCTAssertEqual(count, 2)
      }
    }

    func testMongoCollectionUpdateOneCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]
      let document3: Document = ["name": "john", "breed": "cane corso"]
      let document4: Document = ["name": "ted", "breed": "bullmastiff"]
      let document5: Document = ["name": "bill", "breed": "great dane"]

      collection.insertMany([document, document2, document3, document4]).await(self)
      collection.updateOneDocument(filter: document, update: document2).await(self)
      { updateResult in
        XCTAssertEqual(updateResult.matchedCount, 1)
        XCTAssertEqual(updateResult.modifiedCount, 1)
        XCTAssertNil(updateResult.documentId)
      }

      collection.updateOneDocument(filter: document5, update: document2, upsert: true).await(self)
      { updateResult in
        XCTAssertEqual(updateResult.matchedCount, 0)
        XCTAssertEqual(updateResult.modifiedCount, 0)
        XCTAssertNotNil(updateResult.documentId)
      }
    }

    func testMongoCollectionUpdateManyCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]
      let document3: Document = ["name": "john", "breed": "cane corso"]
      let document4: Document = ["name": "ted", "breed": "bullmastiff"]
      let document5: Document = ["name": "bill", "breed": "great dane"]

      collection.insertMany([document, document2, document3, document4]).await(self)
      collection.updateManyDocuments(filter: document, update: document2).await(self)
      { updateResult in
        XCTAssertEqual(updateResult.matchedCount, 1)
        XCTAssertEqual(updateResult.modifiedCount, 1)
        XCTAssertNil(updateResult.documentId)
      }
      collection.updateManyDocuments(filter: document5, update: document2, upsert: true).await(self)
      { updateResult in
        XCTAssertEqual(updateResult.matchedCount, 0)
        XCTAssertEqual(updateResult.modifiedCount, 0)
        XCTAssertNotNil(updateResult.documentId)
      }
    }

    func testMongoCollectionFindAndUpdateCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]
      let document3: Document = ["name": "john", "breed": "cane corso"]

      collection.findOneAndUpdate(filter: document, update: document2).await(self)

      let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
      collection.findOneAndUpdate(filter: document2, update: document3, options: options1).await(self)
      { updateResult in
        guard let updateResult
        else
        {
          XCTFail("Should find")
          return
        }
        XCTAssertEqual(updateResult["name"]??.stringValue, "john")
      }

      let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
      collection.findOneAndUpdate(filter: document, update: document2, options: options2).await(self)
      { updateResult in
        guard let updateResult
        else
        {
          XCTFail("Should find")
          return
        }
        XCTAssertEqual(updateResult["name"]??.stringValue, "rex")
      }
    }

    func testMongoCollectionFindAndReplaceCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      let document2: Document = ["name": "rex", "breed": "cane corso"]
      let document3: Document = ["name": "john", "breed": "cane corso"]

      collection.findOneAndReplace(filter: document, replacement: document2).await(self)
      { updateResult in
        XCTAssertNil(updateResult)
      }

      let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, true)
      collection.findOneAndReplace(filter: document2, replacement: document3, options: options1).await(self)
      { updateResult in
        guard let updateResult
        else
        {
          XCTFail("Should find")
          return
        }
        XCTAssertEqual(updateResult["name"]??.stringValue, "john")
      }

      let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], true, false)
      collection.findOneAndReplace(filter: document, replacement: document2, options: options2).await(self)
      { updateResult in
        XCTAssertNil(updateResult)
      }
    }

    func testMongoCollectionFindAndDeleteCombine() throws
    {
      let collection = try setupMongoCollection(for: Dog.self)
      let document: Document = ["name": "fido", "breed": "cane corso"]
      collection.insertMany([document]).await(self)

      collection.findOneAndDelete(filter: document).await(self)
      { updateResult in
        XCTAssertNotNil(updateResult)
      }
      collection.findOneAndDelete(filter: document).await(self)
      { updateResult in
        XCTAssertNil(updateResult)
      }

      collection.insertMany([document]).await(self)
      let options1 = FindOneAndModifyOptions(["name": 1], [["_id": 1]], false, false)
      collection.findOneAndDelete(filter: document, options: options1).await(self)
      { deleteResult in
        XCTAssertNotNil(deleteResult)
      }
      collection.findOneAndDelete(filter: document, options: options1).await(self)
      { deleteResult in
        XCTAssertNil(deleteResult)
      }

      collection.insertMany([document]).await(self)
      let options2 = FindOneAndModifyOptions(["name": 1], [["_id": 1]])
      collection.findOneAndDelete(filter: document, options: options2).await(self)
      { deleteResult in
        XCTAssertNotNil(deleteResult)
      }
      collection.findOneAndDelete(filter: document, options: options2).await(self)
      { deleteResult in
        XCTAssertNil(deleteResult)
      }

      collection.insertMany([document]).await(self)
      collection.find(filter: [:]).await(self)
      { updateResult in
        XCTAssertEqual(updateResult.count, 1)
      }
    }

    func testCallFunctionCombine()
    {
      let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
      let password = randomString(10)

      app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

      let credentials = Credentials.emailPassword(email: email, password: password)
      app.login(credentials: credentials).await(self)
      { user in
        XCTAssertNotNil(user)
      }

      app.currentUser?.functions.sum([1, 2, 3, 4, 5]).await(self)
      { bson in
        guard case let .int32(sum) = bson
        else
        {
          XCTFail("Should be int32")
          return
        }
        XCTAssertEqual(sum, 15)
      }

      app.currentUser?.functions.updateUserData([["favourite_colour": "green", "apples": 10]]).await(self)
      { bson in
        guard case let .bool(upd) = bson
        else
        {
          XCTFail("Should be bool")
          return
        }
        XCTAssertTrue(upd)
      }
    }

    func testAPIKeyAuthCombine()
    {
      let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
      let password = randomString(10)

      app.emailPasswordAuth.registerUser(email: email, password: password).await(self)

      let user = app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)

      let apiKey = user.apiKeysAuth.createAPIKey(named: "my-api-key").await(self)
      user.apiKeysAuth.fetchAPIKey(apiKey.objectId).await(self)
      user.apiKeysAuth.fetchAPIKeys().await(self)
      { userApiKeys in
        XCTAssertEqual(userApiKeys.count, 1)
      }

      user.apiKeysAuth.disableAPIKey(apiKey.objectId).await(self)
      user.apiKeysAuth.enableAPIKey(apiKey.objectId).await(self)
      user.apiKeysAuth.deleteAPIKey(apiKey.objectId).await(self)
    }

    func testPushRegistrationCombine()
    {
      let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
      let password = randomString(10)

      app.emailPasswordAuth.registerUser(email: email, password: password).await(self)
      app.login(credentials: Credentials.emailPassword(email: email, password: password)).await(self)

      let client = app.pushClient(serviceName: "gcm")
      client.registerDevice(token: "some-token", user: app.currentUser!).await(self)
      client.deregisterDevice(user: app.currentUser!).await(self)
    }
  }

  @available(macOS 13, *)
  class CombineFlexibleSyncTests: SwiftSyncTestCase
  {
    override var objectTypes: [ObjectBase.Type]
    {
      [SwiftPerson.self, SwiftTypesSyncObject.self]
    }

    override func configuration(user: User) -> Realm.Configuration
    {
      user.flexibleSyncConfiguration()
    }

    override func createApp() throws -> String
    {
      try createFlexibleSyncApp()
    }

    var cancellables: Set<AnyCancellable> = []
    override func tearDown()
    {
      cancellables.forEach { $0.cancel() }
      cancellables = []
      super.tearDown()
    }

    func testFlexibleSyncCombineWrite() throws
    {
      try write
      { realm in
        for i in 1 ... 25
        {
          let person = SwiftPerson(firstName: "\(self.name)",
                                   lastName: "lastname_\(i)",
                                   age: i)
          realm.add(person)
        }
      }

      let realm = try openRealm()
      checkCount(expected: 0, realm, SwiftPerson.self)

      let subscriptions = realm.subscriptions
      XCTAssertEqual(subscriptions.count, 0)

      let ex = expectation(description: "state change complete")
      subscriptions.updateSubscriptions
      {
        subscriptions.append(QuerySubscription<SwiftPerson>(name: "person_age_10")
        {
          $0.age > 10 && $0.firstName == "\(self.name)"
        })
      }.sink(receiveCompletion: { @Sendable _ in },
             receiveValue: { @Sendable _ in ex.fulfill() }).store(in: &cancellables)

      waitForExpectations(timeout: 20.0, handler: nil)

      waitForDownloads(for: realm)
      checkCount(expected: 15, realm, SwiftPerson.self)
    }

    func testFlexibleSyncCombineWriteFails() throws
    {
      let realm = try openRealm()
      checkCount(expected: 0, realm, SwiftPerson.self)

      let subscriptions = realm.subscriptions
      XCTAssertEqual(subscriptions.count, 0)

      let ex = expectation(description: "state change error")
      subscriptions.updateSubscriptions
      {
        subscriptions.append(QuerySubscription<SwiftTypesSyncObject>(name: "swiftObject_longCol")
        {
          $0.longCol == Int64(1)
        })
      }
      .sink(receiveCompletion: { result in
        if case let .failure(error as Realm.Error) = result
        {
          XCTAssertEqual(error.code, .subscriptionFailed)
          guard case .error = subscriptions.state
          else
          {
            return XCTFail("Adding a query for a not queryable field should change the subscription set state to error")
          }
        }
        else
        {
          XCTFail("Expected an error but got \(result)")
        }
        ex.fulfill()
      }, receiveValue: { _ in })
      .store(in: &cancellables)

      waitForExpectations(timeout: 20.0, handler: nil)

      waitForDownloads(for: realm)
      checkCount(expected: 0, realm, SwiftPerson.self)
    }
  }

#endif // os(macOS)
