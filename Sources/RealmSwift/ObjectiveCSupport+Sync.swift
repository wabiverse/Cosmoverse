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
 :nodoc:
 **/
public extension ObjectiveCSupport
{
  /// Convert a `SyncConfiguration` to a `RLMSyncConfiguration`.
  static func convert(object: SyncConfiguration) -> RLMSyncConfiguration
  {
    object.config
  }

  /// Convert a `RLMSyncConfiguration` to a `SyncConfiguration`.
  static func convert(object: RLMSyncConfiguration) -> SyncConfiguration
  {
    SyncConfiguration(config: object)
  }

  /// Convert a `Credentials` to a `RLMCredentials`
  static func convert(object: Credentials) -> RLMCredentials
  {
    switch object
    {
      case let .facebook(accessToken):
        RLMCredentials(facebookToken: accessToken)
      case let .google(serverAuthCode):
        RLMCredentials(googleAuthCode: serverAuthCode)
      case let .googleId(token):
        RLMCredentials(googleIdToken: token)
      case let .apple(idToken):
        RLMCredentials(appleToken: idToken)
      case let .emailPassword(email, password):
        RLMCredentials(email: email, password: password)
      case let .jwt(token):
        RLMCredentials(jwt: token)
      case let .function(payload):
        RLMCredentials(functionPayload: ObjectiveCSupport.convert(object: AnyBSON(payload)) as! [String: RLMBSON])
      case let .userAPIKey(APIKey):
        RLMCredentials(userAPIKey: APIKey)
      case let .serverAPIKey(serverAPIKey):
        RLMCredentials(serverAPIKey: serverAPIKey)
      case .anonymous:
        RLMCredentials.anonymous()
    }
  }
}
