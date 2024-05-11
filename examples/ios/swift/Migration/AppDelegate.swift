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
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
  var window: UIWindow?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
  {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = UIViewController()
    window?.makeKeyAndVisible()

    #if CREATE_EXAMPLES
      addExampleDataToRealm(exampleData)
    #else
      performMigration()
    #endif

    return true
  }

  private func addExampleDataToRealm(_ exampleData: (Realm) -> Void)
  {
    let url = realmUrl(for: schemaVersion, usingTemplate: false)
    let configuration = Realm.Configuration(fileURL: url, schemaVersion: UInt64(schemaVersion))
    let realm = try! Realm(configuration: configuration)

    try! realm.write
    {
      exampleData(realm)
    }
  }

  /// Any version before the current versions will be migrated to check if all version combinations work.
  private func performMigration()
  {
    for oldSchemaVersion in 0 ..< schemaVersion
    {
      let url = realmUrl(for: oldSchemaVersion, usingTemplate: true)
      let realmConfiguration = Realm.Configuration(fileURL: url, schemaVersion: UInt64(schemaVersion), migrationBlock: migrationBlock)
      try! Realm.performMigration(for: realmConfiguration)
      let realm = try! Realm(configuration: realmConfiguration)
      migrationCheck(realm)
    }
  }

  private func realmUrl(for schemaVersion: Int, usingTemplate: Bool) -> URL
  {
    let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
    let defaultParentURL = defaultURL.deletingLastPathComponent()
    let fileName = "default-v\(schemaVersion)"
    let destinationUrl = defaultParentURL.appendingPathComponent(fileName + ".realm")
    if FileManager.default.fileExists(atPath: destinationUrl.path)
    {
      try! FileManager.default.removeItem(at: destinationUrl)
    }
    if usingTemplate
    {
      let bundleUrl = Bundle.main.url(forResource: fileName, withExtension: "realm")!
      try! FileManager.default.copyItem(at: bundleUrl, to: destinationUrl)
    }

    return destinationUrl
  }
}
