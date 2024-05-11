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

class Reminder: EmbeddedObject, ObjectKeyIdentifiable
{
  enum Priority: Int, PersistableEnum, CaseIterable, Identifiable, CustomStringConvertible
  {
    var id: Int { rawValue }

    case low, medium, high

    var description: String
    {
      switch self
      {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
      }
    }
  }

  @Persisted var title = ""
  @Persisted var notes = ""
  @Persisted var isFlagged = false
  @Persisted var date = Date()
  @Persisted var isComplete = false
  @Persisted var priority: Priority = .low
}

class ReminderList: Object, ObjectKeyIdentifiable
{
  @Persisted var name = "New List"
  @Persisted var icon = "list.bullet"
  @Persisted var reminders = RealmSwift.List<Reminder>()
  var firstLetter: String
  {
    guard let char = name.first
    else
    {
      return ""
    }
    return String(char)
  }
}
