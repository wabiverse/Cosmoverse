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

class RepositoriesViewController: UICollectionViewController, UITextFieldDelegate
{
  @IBOutlet var sortOrderControl: UISegmentedControl!
  @IBOutlet var searchField: UITextField!

  var results: Results<Repository>?
  var token: NotificationToken?

  deinit
  {
    token?.invalidate()
  }

  override func viewDidLoad()
  {
    super.viewDidLoad()

    let realm = try! Realm()
    token = realm.observe
    { [weak self] _, _ in
      self?.reloadData()
    }

    var components = URLComponents(string: "https://api.github.com/search/repositories")!
    components.queryItems = [
      URLQueryItem(name: "q", value: "language:objc"),
      URLQueryItem(name: "sort", value: "stars"),
      URLQueryItem(name: "order", value: "desc")
    ]
    URLSession.shared.dataTask(with: URLRequest(url: components.url!))
    { data, _, error in
      if let error
      {
        print(error)
        return
      }

      do
      {
        let repositories = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
        let items = repositories["items"] as! [[String: AnyObject]]

        let realm = try Realm()
        try realm.write
        {
          for item in items
          {
            let repository = Repository()
            repository.identifier = String(item["id"] as! Int)
            repository.name = item["name"] as? String
            repository.avatarURL = item["owner"]!["avatar_url"] as? String

            realm.add(repository, update: .modified)
          }
        }
      }
      catch
      {
        print(error.localizedDescription)
      }
    }.resume()
  }

  override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int
  {
    results?.count ?? 0
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RepositoryCell
    let repository = results![indexPath.item]
    cell.titleLabel.text = repository.name

    URLSession.shared.dataTask(with: URLRequest(url: URL(string: repository.avatarURL!)!))
    { data, _, error in
      if let error
      {
        print(error.localizedDescription)
        return
      }

      DispatchQueue.main.async
      {
        let image = UIImage(data: data!)!
        cell.avatarImageView!.image = image
      }
    }.resume()

    return cell
  }

  func reloadData()
  {
    let realm = try! Realm()
    results = realm.objects(Repository.self)
    if let text = searchField.text, !text.isEmpty
    {
      results = results?.filter("name contains[c] %@", text)
    }
    results = results?.sorted(byKeyPath: "name", ascending: sortOrderControl!.selectedSegmentIndex == 0)

    collectionView?.reloadData()
  }

  @IBAction func valueChanged(sender _: AnyObject)
  {
    reloadData()
  }

  @IBAction func clearSearchField(sender _: AnyObject)
  {
    searchField.text = nil
    reloadData()
  }

  func textFieldDidEndEditing(_: UITextField)
  {
    reloadData()
  }
}
