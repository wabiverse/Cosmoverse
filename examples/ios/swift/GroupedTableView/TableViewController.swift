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
  @Persisted var phoneNumber: String
  @Persisted var date: Date
  @Persisted var contactName: String
  var firstLetter: String
  {
    guard let char = contactName.first
    else
    {
      return ""
    }
    return String(char)
  }
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
  var notificationToken: NotificationToken?
  var realm: Realm!
  var sectionedResults: SectionedResults<String, DemoObject>!

  override func viewDidLoad()
  {
    super.viewDidLoad()

    setupUI()
    realm = try! Realm()
    sectionedResults = realm.objects(DemoObject.self)
      .sectioned(by: \.firstLetter, ascending: true)

    // Set realm notification block
    notificationToken = sectionedResults.observe
    { change in
      switch change
      {
        case .initial:
          break
        case let .update(_,
                         deletions: deletions,
                         insertions: insertions,
                         modifications: modifications,
                         sectionsToInsert: sectionsToInsert,
                         sectionsToDelete: sectionsToDelete):
          self.tableView.performBatchUpdates
          {
            self.tableView.deleteRows(at: deletions, with: .automatic)
            self.tableView.insertRows(at: insertions, with: .automatic)
            self.tableView.reloadRows(at: modifications, with: .automatic)
            self.tableView.insertSections(sectionsToInsert, with: .automatic)
            self.tableView.deleteSections(sectionsToDelete, with: .automatic)
          }
      }
    }
    tableView.reloadData()
  }

  // UI

  func setupUI()
  {
    tableView.register(Cell.self, forCellReuseIdentifier: "cell")

    title = "GroupedTableView"
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "BG Add", style: .plain, target: self, action: #selector(TableViewController.backgroundAdd))
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(TableViewController.add))
  }

  // Table view data source

  override func numberOfSections(in _: UITableView) -> Int
  {
    sectionedResults.count
  }

  override func sectionIndexTitles(for _: UITableView) -> [String]?
  {
    sectionedResults.allKeys
  }

  override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String?
  {
    sectionedResults[section].key
  }

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int
  {
    sectionedResults[section].count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell

    let object = sectionedResults[indexPath]
    cell.textLabel?.text = "\(object.contactName): \(object.phoneNumber)"
    cell.detailTextLabel?.text = object.date.description

    return cell
  }

  override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
  {
    if editingStyle == .delete
    {
      try! realm.write
      {
        realm.delete(sectionedResults[indexPath])
      }
    }
  }

  // MARK: Actions

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
          realm.create(DemoObject.self, value: ["contactName": randomName(), "date": NSDate(), "phoneNumber": randomPhoneNumber()])
        }
        try! realm.commitWrite()
      }
    }
  }

  @objc func add()
  {
    try! realm.write
    {
      realm.create(DemoObject.self, value: ["contactName": randomName(), "date": NSDate(), "phoneNumber": randomPhoneNumber()])
    }
  }
}

// MARK: Helpers

func randomPhoneNumber() -> String
{
  "555-55\(Int.random(in: 0 ... 9))5-55\(Int.random(in: 0 ... 9))"
}

func randomName() -> String
{
  ["John", "Jane", "Mary", "Eric", "Sarah", "Sally"].randomElement()!
}
