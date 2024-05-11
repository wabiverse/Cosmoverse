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
import SwiftUI

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

  @Persisted var title: String
  @Persisted var notes: String
  @Persisted var isFlagged: Bool
  @Persisted var date: Date
  @Persisted var isComplete: Bool
  @Persisted var priority: Priority = .low
}

class ReminderList: Object, ObjectKeyIdentifiable
{
  @Persisted var name = "New List"
  @Persisted var icon: String = "list.bullet"
  @Persisted var reminders: RealmSwift.List<Reminder>
}

struct FocusableTextField: UIViewRepresentable
{
  class Coordinator: NSObject, UITextFieldDelegate
  {
    @Binding var text: String
    var didBecomeFirstResponder = false

    init(text: Binding<String>)
    {
      _text = text
    }

    func textFieldDidChangeSelection(_ textField: UITextField)
    {
      text = textField.text ?? ""
    }
  }

  let title: String
  @Binding var text: String
  @Binding var isFirstResponder: Bool

  init(_ title: String, text: Binding<String>, isFirstResponder: Binding<Bool>)
  {
    self.title = title
    _text = text
    _isFirstResponder = isFirstResponder
  }

  func makeUIView(context: UIViewRepresentableContext<Self>) -> UITextField
  {
    let textField = UITextField(frame: .zero)
    textField.placeholder = title
    textField.delegate = context.coordinator
    return textField
  }

  func makeCoordinator() -> Coordinator
  {
    Coordinator(text: $text)
  }

  func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<Self>)
  {
    uiView.text = text
    if isFirstResponder, !context.coordinator.didBecomeFirstResponder
    {
      uiView.becomeFirstResponder()
      context.coordinator.didBecomeFirstResponder = true
    }
  }
}

struct ReminderRowView: View
{
  @ObservedRealmObject var list: ReminderList
  @ObservedRealmObject var reminder: Reminder
  @State var hasFocus: Bool
  @State var showReminderForm = false

  var body: some View
  {
    NavigationLink(destination: ReminderFormView(list: list,
                                                 reminder: reminder,
                                                 showReminderForm: $showReminderForm), isActive: $showReminderForm)
    {
      FocusableTextField("title", text: reminder.bind(\.title), isFirstResponder: $hasFocus).textCase(.lowercase)
    }.isDetailLink(true)
  }
}

struct ReminderFormView: View
{
  @ObservedRealmObject var list: ReminderList
  @ObservedRealmObject var reminder: Reminder
  @Binding var showReminderForm: Bool

  var body: some View
  {
    Form
    {
      TextField("title", text: $reminder.title)
      DatePicker("date", selection: $reminder.date)
      Picker("priority", selection: $reminder.priority, content: {
        ForEach(Reminder.Priority.allCases)
        { priority in
          Text(priority.description).tag(priority)
        }
      })
    }
    .navigationTitle(reminder.title)
    .navigationBarItems(trailing:
      Button("Save")
      {
        if reminder.realm == nil
        {
          $list.reminders.append(reminder)
        }
        showReminderForm.toggle()
      }.disabled(reminder.title.isEmpty))
  }
}

struct ReminderListView: View
{
  @ObservedRealmObject var list: ReminderList
  @State var newReminderAdded = false
  @State var showReminderForm = false

  func shouldFocusReminder(_ reminder: Reminder) -> Bool
  {
    newReminderAdded &&
      list.reminders.lastIndex(of: reminder) == (list.reminders.count - 1)
  }

  var body: some View
  {
    VStack
    {
      List
      {
        ForEach(list.reminders)
        { reminder in
          ReminderRowView(list: list,
                          reminder: reminder,
                          hasFocus: shouldFocusReminder(reminder))
        }
        .onMove(perform: $list.reminders.move)
        .onDelete(perform: $list.reminders.remove)
      }
    }.navigationTitle(list.name)
    .navigationBarItems(trailing: HStack
    {
      EditButton()
      Button("add")
      {
        newReminderAdded = true
        $list.reminders.append(Reminder())
      }.accessibility(identifier: "addReminder")
    })
  }
}

struct ReminderListRowView: View
{
  @ObservedRealmObject var list: ReminderList

  var body: some View
  {
    HStack
    {
      Image(systemName: list.icon)
      TextField("List Name", text: $list.name)
      Spacer()
      Text("\(list.reminders.count)")
    }.frame(minWidth: 100)
  }
}

struct ReminderListResultsView: View
{
  @ObservedResults(ReminderList.self) var reminders
  @Binding var searchFilter: String

  var body: some View
  {
    let list = List
    {
      ForEach(reminders)
      { list in
        NavigationLink(destination: ReminderListView(list: list))
        {
          ReminderListRowView(list: list).tag(list)
        }.accessibilityIdentifier(list.name)
      }.onDelete(perform: $reminders.remove)
    }
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    {
      list
        .searchable(text: $searchFilter,
                    collection: $reminders,
                    keyPath: \.name)
      {
        ForEach(reminders)
        { remindersFiltered in
          Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
        }
      }
    }
    else
    {
      list
        .onChange(of: searchFilter)
        { value in
          $reminders.where = { $0.name.contains(value, options: .caseInsensitive) }
        }
    }
  }
}

public extension Color
{
  static let lightText = Color(UIColor.lightText)
  static let darkText = Color(UIColor.darkText)

  static let label = Color(UIColor.label)
  static let secondaryLabel = Color(UIColor.secondaryLabel)
  static let tertiaryLabel = Color(UIColor.tertiaryLabel)
  static let quaternaryLabel = Color(UIColor.quaternaryLabel)

  static let systemBackground = Color(UIColor.systemBackground)
  static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
  static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
}

struct SearchView: View
{
  @Binding var searchFilter: String

  var body: some View
  {
    VStack
    {
      Spacer()
      HStack
      {
        Image(systemName: "magnifyingglass").foregroundColor(.gray)
          .padding(.leading, 7)
          .padding(.top, 7)
          .padding(.bottom, 7)
        TextField("search", text: $searchFilter)
          .padding(.top, 7)
          .padding(.bottom, 7)
      }.background(RoundedRectangle(cornerRadius: 15)
        .fill(Color.secondarySystemBackground))
      Spacer()
    }.frame(maxHeight: 40).padding()
  }
}

struct Footer: View
{
  @ObservedResults(ReminderList.self) var lists

  var body: some View
  {
    HStack
    {
      Button(action: {
        $lists.append(ReminderList())
      }, label: {
        HStack
        {
          Image(systemName: "plus.circle")
          Text("Add list")
        }
      }).buttonStyle(BorderlessButtonStyle())
        .padding()
        .accessibility(identifier: "addList")
      Spacer()
    }
  }
}

struct ContentView: View
{
  @State var searchFilter: String = ""

  var body: some View
  {
    NavigationView
    {
      VStack
      {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
        {
          // Don't add a SearchView in case searchable is available
        }
        else
        {
          SearchView(searchFilter: $searchFilter)
        }
        ReminderListResultsView(searchFilter: $searchFilter)
        Spacer()
        Footer()
      }
      .navigationBarItems(trailing: EditButton())
      .navigationTitle("reminders")
    }
  }
}

#if DEBUG
  struct Content_Preview: PreviewProvider
  {
    static var previews: some View
    {
      ContentView()
    }
  }
#endif
