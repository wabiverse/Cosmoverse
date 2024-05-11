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

import AuthenticationServices
import RealmSwift
import SwiftUI

/// Your Atlas App Services app ID
let appId = "your-app-id"

struct ContentView: View
{
  @State var accessToken: String = ""
  @State var error: String = ""

  var body: some View
  {
    VStack
    {
      SignInWithAppleView(accessToken: $accessToken, error: $error)
        .frame(width: 200, height: 50, alignment: .center)
      Text(accessToken)
      Text(error)
    }
  }
}

class SignInCoordinator: ASLoginDelegate
{
  var parent: SignInWithAppleView
  var app: App

  init(parent: SignInWithAppleView)
  {
    self.parent = parent
    app = App(id: appId)
    app.authorizationDelegate = self
  }

  @objc func didTapLogin()
  {
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]

    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    app.setASAuthorizationControllerDelegate(for: authorizationController)
    authorizationController.performRequests()
  }

  func authenticationDidComplete(error: Error)
  {
    parent.error = error.localizedDescription
  }

  func authenticationDidComplete(user: User)
  {
    parent.accessToken = user.accessToken ?? "Could not get access token"
  }
}

struct SignInWithAppleView: UIViewRepresentable
{
  @Binding var accessToken: String
  @Binding var error: String

  func makeCoordinator() -> SignInCoordinator
  {
    SignInCoordinator(parent: self)
  }

  func makeUIView(context: Context) -> ASAuthorizationAppleIDButton
  {
    let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
    button.addTarget(context.coordinator, action: #selector(context.coordinator.didTapLogin), for: .touchUpInside)
    return button
  }

  func updateUIView(_: ASAuthorizationAppleIDButton, context _: Context)
  {}
}

struct ContentView_Previews: PreviewProvider
{
  static var previews: some View
  {
    ContentView()
  }
}
