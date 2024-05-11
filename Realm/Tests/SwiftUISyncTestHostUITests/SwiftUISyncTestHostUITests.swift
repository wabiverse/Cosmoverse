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

import RealmSwift
import XCTest

class SwiftUISyncUITests: SwiftSyncTestCase
{
  override func tearDown()
  {
    logoutAllUsers()
    application.terminate()
    super.tearDown()
  }

  override var objectTypes: [ObjectBase.Type]
  {
    [SwiftPerson.self]
  }

  let application = XCUIApplication()

  func populateData(count: Int) throws
  {
    try write
    { realm in
      for i in 1 ... count
      {
        realm.add(SwiftPerson(firstName: name, lastName: randomString(7), age: i))
      }
    }
  }

  func registerEmail() -> String
  {
    let email = "realm_tests_do_autoverify\(randomString(7))@\(randomString(7)).com"
    app.emailPasswordAuth.registerUser(email: email, password: "password").await(self)
    return email
  }

  /// Login for given user
  enum UserType: Int
  {
    case first = 1
    case second = 2
  }

  func loginUser(_ type: UserType)
  {
    let loginButton = application.buttons["login_button_\(type.rawValue)"]
    XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
    loginButton.tap()

    let loggingView = application.staticTexts["logged_view"]
    XCTAssertTrue(loggingView.waitForExistence(timeout: 6))
  }

  func asyncOpen()
  {
    loginUser(.first)

    // Query for button to start syncing
    let syncButtonView = application.buttons["sync_button"]
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()
  }

  func logoutAllUsers()
  {
    let loginButton = application.buttons["logout_users_button"]
    XCTAssertTrue(loginButton.waitForExistence(timeout: 2))
    loginButton.tap()
  }

  func launch(_ test: TestType, _ env: [String: String]? = nil)
  {
    application.launchEnvironment["app_id"] = appId
    application.launchEnvironment["partition_value"] = name
    application.launchEnvironment["email1"] = registerEmail()
    application.launchEnvironment["email2"] = registerEmail()
    application.launchEnvironment["async_view_type"] = test.rawValue
    if let env
    {
      application.launchEnvironment.merge(env, uniquingKeysWith: { $1 })
    }
    application.launch()
    asyncOpen()
  }
}

class PBSSwiftUISyncUITests: SwiftUISyncUITests
{
  // MARK: - AsyncOpen

  func testDownloadRealmAsyncOpenApp() throws
  {
    try populateData(count: 1)
    launch(.asyncOpen)

    // Test progress is greater than 0
    let progressView = application.staticTexts["progress_text_view"]
    XCTAssertTrue(progressView.waitForExistence(timeout: 2))
    let progressValue = progressView.value as! String
    XCTAssertTrue(Int64(progressValue)! > 0)

    // Query for button to navigate to next view
    let nextViewView = application.buttons["show_list_button_view"]
    nextViewView.tap()

    // Test show ListView after syncing realm environment
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 1)
  }

  func testDownloadRealmAsyncOpenAppWithEnvironmentPartitionValue() throws
  {
    try populateData(count: 2)
    launch(.asyncOpenEnvironmentPartition)

    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 2)
  }

  func testDownloadRealmAsyncOpenAppWithEnvironmentConfiguration() throws
  {
    try populateData(count: 3)
    launch(.asyncOpenEnvironmentConfiguration)

    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 3)
  }

  func testObservedResults() throws
  {
    try populateData(count: 2)
    launch(.asyncOpenEnvironmentPartition)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 2)

    loginUser(.second)

    // Query for button to start syncing
    let syncButtonView = application.buttons["sync_button"]
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()

    // Test show ListView after logging new user
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 2)

    try populateData(count: 2)
    XCTAssertTrue(table.cells.element(boundBy: 3).waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 4)

    loginUser(.first)
    // Make sure the first user also has 4 SwiftPerson's
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 4)
  }

  func testObservedSectionedResults() throws
  {
    try write
    { realm in
      realm.add(SwiftPerson(firstName: "Joe", lastName: "Blogs"))
      realm.add(SwiftPerson(firstName: "Jane", lastName: "Doe"))
    }

    launch(.asyncOpenEnvironmentPartition, ["is_sectioned_results": "true"])

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 4) // Includes section headers and cells
    XCTAssertEqual(table.staticTexts.count, 4)

    loginUser(.second)

    // Query for button to start syncing
    let syncButtonView = application.buttons["sync_button"]
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()

    // Test show ListView after logging new user
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 4)

    try write
    { realm in
      realm.add(SwiftPerson(firstName: "Joe", lastName: "Blogs2"))
      realm.add(SwiftPerson(firstName: "Jane", lastName: "Doe2"))
    }
    XCTAssertEqual(table.cells.count, 6)

    loginUser(.first)
    // Make sure the first user also has 4 SwiftPerson's
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 6)
    XCTAssertEqual(table.staticTexts.count, 6)
  }

  func testAsyncOpenMultiUser() throws
  {
    try populateData(count: 3)
    launch(.asyncOpenEnvironmentPartition)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 3)

    loginUser(.second)

    // Query for button to start syncing
    let syncButtonView = application.buttons["sync_button"]
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()

    // Test show ListView after logging new user
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 3)
  }

  func testAsyncOpenAndLogout() throws
  {
    try populateData(count: 2)
    launch(.asyncOpenEnvironmentPartition)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 2)

    let logoutButtonView = application.buttons["logout_button"]
    XCTAssertTrue(logoutButtonView.waitForExistence(timeout: 2))
    logoutButtonView.tap()

    let waitingUserView = application.buttons["waiting_user_view"]
    XCTAssertTrue(waitingUserView.waitForExistence(timeout: 2))
  }

  func testAsyncOpenWithDeferRealmConfiguration() throws
  {
    try populateData(count: 20)
    launch(.asyncOpenCustomConfiguration)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 20)

    // Check if there is more than one realm when using environment values.
    let enumerator = FileManager.default.enumerator(at: clientDataRoot(), includingPropertiesForKeys: [.nameKey, .isDirectoryKey])
    var counter = 0
    while let element = enumerator?.nextObject() as? URL
    {
      if element.path.hasSuffix(".realm") { counter += 1 }
    }
    // Synced Realm and Sync Metadata
    XCTAssertEqual(counter, 2)
  }

  // MARK: - AutoOpen

  func testDownloadRealmAutoOpenApp() throws
  {
    try populateData(count: 1)
    launch(.autoOpen)

    // Test progress is greater than 0
    let progressView = application.staticTexts["progress_text_view"]
    XCTAssertTrue(progressView.waitForExistence(timeout: 2))
    let progressValue = progressView.value as! String
    XCTAssertTrue(Int64(progressValue)! > 0)

    // Query for button to navigate to next view
    let nextViewView = application.buttons["show_list_button_view"]
    nextViewView.tap()

    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 1)
  }

  func testDownloadRealmAutoOpenAppWithEnvironmentPartitionValue() throws
  {
    try populateData(count: 2)
    launch(.autoOpenEnvironmentPartition)

    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 2)
  }

  func testDownloadRealmAutoOpenAppWithEnvironmentConfiguration() throws
  {
    try populateData(count: 3)
    launch(.autoOpenEnvironmentConfiguration)

    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 3)
  }

  func testAutoOpenMultiUser() throws
  {
    try populateData(count: 3)
    launch(.autoOpenEnvironmentPartition)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 3)

    loginUser(.second)

    // Query for button to start syncing
    let syncButtonView = application.buttons["sync_button"]
    XCTAssertTrue(syncButtonView.waitForExistence(timeout: 2))
    syncButtonView.tap()

    // Test show ListView after logging new user
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 3)
  }

  func testAutoOpenAndLogout() throws
  {
    try populateData(count: 2)
    launch(.autoOpenEnvironmentPartition)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 2)

    let logoutButtonView = application.buttons["logout_button"]
    XCTAssertTrue(logoutButtonView.waitForExistence(timeout: 2))
    logoutButtonView.tap()

    let waitingUserView = application.buttons["waiting_user_view"]
    XCTAssertTrue(waitingUserView.waitForExistence(timeout: 2))
  }

  func testAutoOpenWithDeferRealmConfiguration() throws
  {
    try populateData(count: 20)
    launch(.autoOpenCustomConfiguration)

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 20)

    // Check if there is more than one realm when using environment values.
    let enumerator = FileManager.default.enumerator(at: clientDataRoot(), includingPropertiesForKeys: [.nameKey, .isDirectoryKey])
    var counter = 0
    while let element = enumerator?.nextObject() as? URL
    {
      if element.path.hasSuffix(".realm") { counter += 1 }
    }
    // Synced Realm and Sync Metadata
    XCTAssertEqual(counter, 2)
  }
}

class FLXSwiftUISyncUITests: SwiftUISyncUITests
{
  override func createApp() throws -> String
  {
    try createFlexibleSyncApp()
  }

  override func configuration(user: User) -> Realm.Configuration
  {
    user.flexibleSyncConfiguration()
  }

  func testFlexibleSyncAsyncOpenRoundTrip() throws
  {
    try populateData(count: 10)
    launch(.asyncOpenFlexibleSync)

    // Query for button to navigate to next view
    let nextViewView = application.buttons["show_list_button_view"]
    XCTAssertTrue(nextViewView.waitForExistence(timeout: 10))
    nextViewView.tap()

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 5)
  }

  func testFlexibleSyncAutoOpenRoundTrip() throws
  {
    try populateData(count: 20)
    launch(.autoOpenFlexibleSync)

    // Query for button to navigate to next view
    let nextViewView = application.buttons["show_list_button_view"]
    XCTAssertTrue(nextViewView.waitForExistence(timeout: 10))
    nextViewView.tap()

    // Test show ListView after syncing realm
    let table = application.tables.firstMatch
    XCTAssertTrue(table.waitForExistence(timeout: 6))
    XCTAssertEqual(table.cells.count, 18)
  }
}
