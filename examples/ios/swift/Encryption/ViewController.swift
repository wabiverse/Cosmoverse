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
import Security
import UIKit

/// Model definition
class EncryptionObject: Object
{
  @Persisted var stringProp: String
}

class ViewController: UIViewController
{
  let textView = UITextView(frame: UIScreen.main.applicationFrame)

  /// Create a view to display output in
  override func loadView()
  {
    super.loadView()
    view.addSubview(textView)
  }

  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)

    // Use an autorelease pool to close the Realm at the end of the block, so
    // that we can try to reopen it with different keys
    autoreleasepool
    {
      let configuration = Realm.Configuration(encryptionKey: getKey() as Data)
      let realm = try! Realm(configuration: configuration)

      // Add an object
      try! realm.write
      {
        let obj = EncryptionObject()
        obj.stringProp = "abcd"
        realm.add(obj)
      }
    }

    // Opening with wrong key fails since it decrypts to the wrong thing
    autoreleasepool
    {
      do
      {
        let configuration = Realm.Configuration(encryptionKey: "1234567890123456789012345678901234567890123456789012345678901234".data(using: .utf8, allowLossyConversion: false))
        _ = try Realm(configuration: configuration)
      }
      catch
      {
        log(text: "Open with wrong key: \(error)")
      }
    }

    // Opening without supplying a key at all fails
    autoreleasepool
    {
      do
      {
        _ = try Realm()
      }
      catch
      {
        log(text: "Open with no key: \(error)")
      }
    }

    // Reopening with the correct key works and can read the data
    autoreleasepool
    {
      let configuration = Realm.Configuration(encryptionKey: getKey() as Data)
      let realm = try! Realm(configuration: configuration)
      if let stringProp = realm.objects(EncryptionObject.self).first?.stringProp
      {
        log(text: "Saved object: \(stringProp)")
      }
    }
  }

  func log(text: String)
  {
    textView.text += "\(text)\n\n"
  }

  func getKey() -> NSData
  {
    // Identifier for our keychain entry - should be unique for your application
    let keychainIdentifier = "io.Realm.EncryptionExampleKey"
    let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!

    // First check in the keychain for an existing key
    var query: [NSString: AnyObject] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
      kSecAttrKeySizeInBits: 512 as AnyObject,
      kSecReturnData: true as AnyObject
    ]

    // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
    // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
    var dataTypeRef: AnyObject?
    var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
    if status == errSecSuccess
    {
      return dataTypeRef as! NSData
    }

    // No pre-existing key from this application, so generate a new one
    let keyData = NSMutableData(length: 64)!
    let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
    assert(result == 0, "Failed to get random bytes")

    // Store the key in the keychain
    query = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
      kSecAttrKeySizeInBits: 512 as AnyObject,
      kSecValueData: keyData
    ]

    status = SecItemAdd(query as CFDictionary, nil)
    assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

    return keyData
  }
}
