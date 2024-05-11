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

////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import RealmSwift
import SwiftUI

class Series: Object
{
  @Persisted var title: String
  @Persisted var episodes: RealmSwift.List<Movie>
}

class Movie: Object
{
  @Persisted var title: String
  @Persisted var episodeNumber: Int
  @Persisted var length: Int
  @Persisted(originProperty: "episodes")
  var series: LinkingObjects<Series>
}

class SeriesModel: Projection<Series>
{
  @Projected(\Series.title) var title
  @Projected(\Series.episodes.count) var epCount
  @Projected(\Series.episodes.first?.title.quoted) var firstEpisode
  @Projected(\Series.episodes) var episodes
}

extension String
{
  var quoted: String
  {
    "\"\(self)\""
  }
}

struct SeriesCellView: View
{
  @ObservedRealmObject var series: SeriesModel

  var body: some View
  {
    VStack
    {
      HStack
      {
        Text(series.title)
        Text("\(series.epCount) \(series.epCount == 1 ? "episode" : "episodes")")
          .font(.footnote)
      }
      if let firstTitle = series.firstEpisode, !firstTitle.isEmpty
      {
        Text("start watch from " + firstTitle)
          .font(.footnote)
      }
    }
  }
}

struct EpisodeCellView: View
{
  @ObservedRealmObject var episode: Movie

  var body: some View
  {
    Text(episode.title)
      .padding()
  }
}

struct SeriesView: View
{
  @ObservedRealmObject var series: SeriesModel
  var body: some View
  {
    VStack
    {
      Text("Episodes")
      List($series.episodes)
      { episode in
        EpisodeCellView(episode: episode.wrappedValue)
      }
    }
  }
}

struct ContentView: View
{
  @Environment(\.realm) var realm
  @ObservedResults(SeriesModel.self) var series

  var body: some View
  {
    NavigationView
    {
      List
      {
        ForEach(series)
        { series in
          NavigationLink(destination: SeriesView(series: series))
          {
            SeriesCellView(series: series)
          }
        }
      }
    }
    .navigationTitle("Movies")
    .onAppear(perform: fillData)
  }

  /// Add records to display in the view
  func fillData()
  {
    if realm.objects(Movie.self).isEmpty
    {
      let sw = Series(value: ["Space Shooter",
                              [["Revived Beliefs", 4],
                               ["The Tyrany Evens the Score", 5],
                               ["Comeback of Magician", 6],
                               ["The Mirage Hazard", 1],
                               ["Offence of Siblings", 2],
                               ["Vendetta of Bad Guys", 3]]])
      try! realm.write
      {
        realm.add(sw)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider
{
  static var previews: some View
  {
    ContentView()
  }
}
