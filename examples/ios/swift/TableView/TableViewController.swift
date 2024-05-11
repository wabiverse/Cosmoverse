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

class DemoObject: Object
{
  @Persisted var title: String
  @Persisted var date: Date
}

class Cell: UITableViewCell
{
  override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String!)
  {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }

  @available(*, unavailable)
  required init(coder _: NSCoder)
  {
    fatalError("NSCoding not supported")
  }
}

class TableViewController: UITableViewController
{
  let realm = try! Realm()
  let results = try! Realm().objects(DemoObject.self).sorted(byKeyPath: "date")
  var notificationToken: NotificationToken?

  override func viewDidLoad()
  {
    super.viewDidLoad()

    setupUI()

    // Set results notification block
    notificationToken = results.observe
    { (changes: RealmCollectionChange) in
      switch changes
      {
        case .initial:
          // Results are now populated and can be accessed without blocking the UI
          self.tableView.reloadData()
        case let .update(_, deletions, insertions, modifications):
          // Query results have changed, so apply them to the TableView
          self.tableView.beginUpdates()
          self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
          self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
          self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
          self.tableView.endUpdates()
        case let .error(err):
          // An error occurred while opening the Realm file on the background worker thread
          fatalError("\(err)")
      }
    }
  }

  // UI

  func setupUI()
  {
    tableView.register(Cell.self, forCellReuseIdentifier: "cell")

    title = "TableView"
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "BG Add", style: .plain,
                                                       target: self, action: #selector(backgroundAdd))
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                        target: self, action: #selector(add))
  }

  // Table view data source

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int
  {
    results.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell

    let object = results[indexPath.row]
    cell.textLabel?.text = object.title
    cell.detailTextLabel?.text = object.date.description

    return cell
  }

  override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
  {
    if editingStyle == .delete
    {
      realm.beginWrite()
      realm.delete(results[indexPath.row])
      try! realm.commitWrite()
    }
  }

  // Actions

  @objc func backgroundAdd()
  {
    // Import many items in a background thread
    DispatchQueue.global().async
    {
      // Get new realm and table since we are in a new thread
      autoreleasepool
      {
        let realm = try! Realm()
        realm.beginWrite()
        for _ in 0 ..< 5
        {
          // Add row via dictionary. Order is ignored.
          realm.create(DemoObject.self, value: ["title": TableViewController.randomString(), "date": TableViewController.randomDate()])
        }
        try! realm.commitWrite()
      }
    }
  }

  @objc func add()
  {
    realm.beginWrite()
    realm.create(DemoObject.self, value: [TableViewController.randomString(), TableViewController.randomDate()])
    try! realm.commitWrite()
  }

  // Helpers

  class func randomString() -> String
  {
    "Title \(Int.random(in: 0 ..< 100))"
  }

  class func randomDate() -> NSDate
  {
    NSDate(timeIntervalSince1970: TimeInterval.random(in: 0 ..< TimeInterval.greatestFiniteMagnitude))
  }
}
