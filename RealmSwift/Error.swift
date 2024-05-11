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

public extension Realm
{
  /**
    Struct that describes the error codes within the Realm error domain.
    The values can be used to catch a variety of _recoverable_ errors, especially those
    happening when initializing a Realm instance.

    ```swift
    let realm: Realm?
    do {
        realm = try Realm()
    } catch Realm.Error.incompatibleLockFile {
        print("Realm Browser app may be attached to Realm on device?")
    }
    ```
   */
  typealias Error = RLMError
}

public extension Realm.Error
{
  /// This error could be returned by completion block when no success and no error were produced
  static let callFailed = Realm.Error(Realm.Error.fail, userInfo: [NSLocalizedDescriptionKey: "Call failed"])

  /// The file URL which produced this error, or `nil` if not applicable
  var fileURL: URL?
  {
    (userInfo[NSFilePathErrorKey] as? String).flatMap(URL.init(fileURLWithPath:))
  }
}

// MARK: Equatable

extension Realm.Error: Equatable {}

// FIXME: we should not be defining this but it's a breaking change to remove
/// Returns a Boolean indicating whether the errors are identical.
public func == (lhs: Error, rhs: Error) -> Bool
{
  lhs._code == rhs._code
    && lhs._domain == rhs._domain
}
