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

import CoreLocation
import Realm

/**
 A struct that represents the coordinates of a point formed by a latitude and a longitude value.

  * Latitude ranges between -90 and 90 degrees, inclusive.
  * Longitude ranges between -180 and 180 degrees, inclusive.

 Values outside this ranges will return nil when trying to create a `GeoPoint`.

 - note: There is no dedicated type to store Geospatial points, instead points should be stored as
 [GeoJson-shaped](https://www.mongodb.com/docs/manual/reference/geojson/) embedded
 object, as explained below. Geospatial queries (`geoWithin`) can only be executed in such a type
 of objects and will throw otherwise.

 Persisting geo points in Realm is currently done using duck-typing, which means that any model class with a specific **shape**
 can be queried as though it contained a geographical location.

 the following is required:
  * A String property with the value of **Point**: `@Persisted var type: String = "Point"`.
  * A List containing a Longitude/Latitude pair: `@Persisted private var coordinates: List<Double>`.

 The recommended approach is using an embedded object.
 ```
 public class Location: EmbeddedObject {
   @Persisted private var coordinates: List<Double>
   @Persisted private var type: String = "Point"

   public var latitude: Double { return coordinates[1] }
   public var longitude: Double { return coordinates[0] }

   convenience init(_ latitude: Double, _ longitude: Double) {
       self.init()
       // Longitude comes first in the coordinates array of a GeoJson document
       coordinates.append(objectsIn: [longitude, latitude])
     }
   }
   ```

 - warning: This structure cannot be persisted and can only be used to build other geospatial shapes
   such as (`GeoBox`, `GeoPolygon` and `GeoCircle`).
 */
public typealias GeoPoint = RLMGeospatialPoint

/**
 A class that represents a rectangle, that can be used in a geospatial `geoWithin`query.

 - warning: This class cannot be persisted and can only be use within a geospatial `geoWithin` query.
 */
public typealias GeoBox = RLMGeospatialBox

public extension GeoBox
{
  /// Initialize a `GeoBox`, with values for bottom left corner and top right corner.
  ///
  /// - Parameter bottomLeft: The bottom left corner of the rectangle.
  /// - Parameter topRight: The top right corner of the rectangle.
  convenience init?(bottomLeft: (Double, Double), topRight: (Double, Double))
  {
    guard let bottomLeftPoint = GeoPoint(latitude: bottomLeft.0, longitude: bottomLeft.1),
          let topRightPoint = GeoPoint(latitude: topRight.0, longitude: topRight.1)
    else
    {
      return nil
    }
    self.init(bottomLeft: bottomLeftPoint, topRight: topRightPoint)
  }
}

/**
 A class that represents a polygon, that can be used in a geospatial `geoWithin`query.

 A `GeoPolygon` describes a shape conformed of and outer `Polygon`, called `outerRing`,
 and 0 or more inner `Polygon`s, called `holes`, which represents an unlimited number of internal holes
 inside the outer `Polygon`.
 A `Polygon` describes a shape conformed by at least three segments, where the last and the first `GeoPoint`
 must be the same to indicate a closed polygon (meaning you need at least 4 points to define a polygon).
 Inner holes in a `GeoPolygon` must  be entirely inside the outer ring

 A `hole` has the following restrictions:
 - Holes may not cross, i.e. the boundary of a hole may not intersect both the interior and the exterior of any other
   hole.
 - Holes may not share edges, i.e. if a hole contains and edge AB, the no other hole may contain it.
 - Holes may share vertices, however no vertex may appear twice in a single hole.
 - No hole may be empty.
 - Only one nesting is allowed.

 - warning: This class cannot be persisted and can only be use within a geospatial `geoWithin` query.

 - warning: Altitude is not used in any of the query calculations.
 */
public typealias GeoPolygon = RLMGeospatialPolygon

public extension GeoPolygon
{
  /// Initialize a `GeoPolygon`, with values for bottom left corner and top right corner.
  ///
  /// Returns `nil` if the `GeoPoints` representing a polygon (outer ring or holes), don't have at least 4 points.
  /// Returns `nil` if the first and the last `GeoPoint` in a polygon are not the same.
  ///
  /// - Parameter outerRing: The polygon's external (outer) ring.
  /// - Parameter holes: The holes (if any) in the polygon.
  convenience init?(outerRing: [(Double, Double)], holes: [[(Double, Double)]] = [])
  {
    let outerRingPoints = outerRing.compactMap(GeoPoint.init)
    let holesPoints = holes.map { $0.compactMap(GeoPoint.init) }
    guard outerRing.count == outerRingPoints.count,
          zip(holes, holesPoints).allSatisfy({ $0.count == $1.count })
    else
    {
      return nil
    }
    self.init(outerRing: outerRingPoints, holes: holesPoints)
  }

  /// Initialize a `GeoPolygon`, with values for bottom left corner and top right corner.
  ///
  /// Returns `nil` if the `GeoPoints` representing a polygon (outer ring or holes), don't have at least 4 points.
  /// Returns `nil` if the first and the last `GeoPoint` in a polygon are not the same.
  ///
  /// - Parameter outerRing: The polygon's external (outer) ring.
  /// - Parameter holes: The holes (if any) in the polygon.
  convenience init?(outerRing: [(Double, Double)], holes: [(Double, Double)]...)
  {
    self.init(outerRing: outerRing, holes: holes.map { $0 })
  }
}

/**
 This structure is a helper to represent/convert a distance. It can be used in geospatial
 queries like those represented by a `GeoCircle`

 - warning: This structure cannot be persisted and can only be used to build other geospatial shapes
 */
public typealias Distance = RLMDistance

/**
 A class that represents a circle, that can be used in a geospatial `geoWithin`query.

 - warning: This class cannot be persisted and can only be use within a geospatial `geoWithin` query.
 */
public typealias GeoCircle = RLMGeospatialCircle

public extension GeoCircle
{
  /// Initialize a `GeoCircle`, from its center and radius in radians.
  ///
  /// - Parameter center: Center of the circle.
  /// - Parameter radiusInRadians: The radius of the circle in radians.
  convenience init?(center: (Double, Double), radiusInRadians: Double)
  {
    guard let centerPoint = GeoPoint(latitude: center.0, longitude: center.1)
    else
    {
      return nil
    }
    self.init(center: centerPoint, radiusInRadians: radiusInRadians)
  }

  /// Initialize a `GeoCircle`, from its center and radius.
  ///
  /// - Parameter center: Center of the circle.
  /// - Parameter radius: Radius of the circle.
  convenience init?(center: (Double, Double), radius: Distance)
  {
    guard let centerPoint = GeoPoint(latitude: center.0, longitude: center.1)
    else
    {
      return nil
    }
    self.init(center: centerPoint, radius: radius)
  }
}
