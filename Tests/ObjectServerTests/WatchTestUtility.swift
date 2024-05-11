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
import RealmSwift
import XCTest

public final class WatchTestUtility: ChangeEventDelegate
{
  private let testCase: XCTestCase
  private let matchingObjectId: ObjectId?
  private let openExpectation: XCTestExpectation
  private let closeExpectation: XCTestExpectation
  private var changeExpectation: XCTestExpectation?
  private let expectError: Bool
  public var didCloseError: Error?

  public init(testCase: XCTestCase, matchingObjectId: ObjectId? = nil, expectError: Bool = false)
  {
    self.testCase = testCase
    self.matchingObjectId = matchingObjectId
    self.expectError = expectError
    openExpectation = testCase.expectation(description: "Open watch stream")
    closeExpectation = testCase.expectation(description: "Close watch stream")
  }

  public func waitForOpen()
  {
    testCase.wait(for: [openExpectation], timeout: 20.0)
  }

  public func waitForClose()
  {
    testCase.wait(for: [closeExpectation], timeout: 20.0)
  }

  public func expectEvent()
  {
    XCTAssertNil(changeExpectation)
    changeExpectation = testCase.expectation(description: "Watch change event")
  }

  public func waitForEvent() throws
  {
    try testCase.wait(for: [XCTUnwrap(changeExpectation)], timeout: 20.0)
    changeExpectation = nil
  }

  public func changeStreamDidOpen(_: ChangeStream)
  {
    openExpectation.fulfill()
  }

  public func changeStreamDidClose(with error: Error?)
  {
    if expectError
    {
      XCTAssertNotNil(error)
    }
    else
    {
      XCTAssertNil(error)
    }

    didCloseError = error
    closeExpectation.fulfill()
  }

  public func changeStreamDidReceive(error: Error)
  {
    XCTAssertNil(error)
  }

  public func changeStreamDidReceive(changeEvent: AnyBSON?)
  {
    XCTAssertNotNil(changeEvent)
    XCTAssertNotNil(changeExpectation)
    guard let changeEvent else { return }
    guard let document = changeEvent.documentValue else { return }

    if let matchingObjectId
    {
      let objectId = document["fullDocument"]??.documentValue!["_id"]??.objectIdValue!
      XCTAssertEqual(objectId, matchingObjectId)
    }
    changeExpectation?.fulfill()
  }
}
