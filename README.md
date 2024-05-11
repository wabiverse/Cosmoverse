# About Cosmoverse Database

> [!IMPORANT]
> Please do not attempt to build this project or submit
> issue tickets, as this project is in a early planning
> phase in an effort to see what's possible.
>
> Thanks for your patience.

Cosmoverse is a database that runs directly inside computers, phones, tablets, or wearables like headsets.
This repository holds the source code for the **Linux**, **Windows**, **macOS**, **iOS**, **visionOS**,
**tvOS**, and **watchOS** versions of Cosmoverse Swift & Cosmoverse C++ (with deprecated Objective-C that is being
migrated to C++).

## Why Use Cosmoverse

* **Intuitive to Developers:** Cosmoverse’s object-oriented data model is simple to learn, doesn’t need an ORM, and lets you write less code.
* **Built for Mobile:** Cosmoverse is fully-featured, lightweight, and efficiently uses memory, disk space, and battery life.
* **Designed for Offline Use:** Cosmoverse’s local database persists data on-disk, so apps work as well offline as they do online.
* **[USD Metaverse Device Sync](#)**: Makes it simple to keep a Usd Stage in sync across users, devices, and your backend in real-time. Get started for free with [a template application](#) and [create the cloud backend](#).

## Object-Oriented: Streamline Your Code

Cosmoverse was built for mobile developers, with simplicity in mind. The idiomatic, object-oriented data model can save you thousands of lines of code.

```swift
// Define your models like regular Swift classes
class World: UsdGeom.Sphere {
  @Persisted var translate: UsdGeom.XformOp
  // Create relationships by binding a prim field to another prim
  @Persisted var material: UsdShade.MaterialBindingAPI
}
class SolarSystem: UsdGeom.Xform {
  @Persisted(primaryKey: true) var _path: SdfPath
  @Persisted var translate: UsdGeom.XformOp
  @Persisted var scale: UsdGeom.XformOp

  // Create hierarchies by pointing a Usd.Prim field to another Usd.Prim
  @Persisted var prims: List<World>
}
// Use them like regular Swift objects.
let world = World()
world.translate.set(GfVec3d(0.0, 0.0, 0.0))
world.material.bind(UsdShade.Material())

// Get the default Usd.Stage
let stage = try! Usd.Stage()
// Persist your data easily with a write transaction
try! stage.write {
  stage.add(world)
}
```
## Live Objects: Build Reactive Apps
Cosmoverse’s live objects mean data updated anywhere is automatically updated everywhere.
```swift
// Open the default Usd.Stage.
let stage = try! Usd.Stage()

var token: NotificationToken?

let world = World()
world.translate.set(GfVec3d(0.0, 0.0, 0.0))

// Create a world in the Usd.Stage.
try! stage.write {
  stage.add(world)
}

// Set up the listener & observe object notifications.
token = world.observe { change in
  switch change {
    case .change(let properties):
      for property in properties {
        print("Property '\(property.name)' changed to '\(property.newValue!)'");
      }
    case .error(let error):
      print("An error occurred: (error)")
    case .deleted:
      print("The object was deleted.")
  }
}

// Update the world's translation to see the effect.
try! stage.write {
  world.translate.set(GfVec3d(1.0, 0.0, 0.0))
}
```
### SwiftUI
Cosmoverse integrates directly with SwiftUI, updating your views so you don't have to.
```swift
struct MetaverseView: View {
  @ObservedResults(SolarSystem.self) var solarSystems

  var body: some View {
    List {
      ForEach(solarSystems) { solarSystem in
        Text(solarSystem.name)
      }
      .onMove(perform: $solarSystem.move)
      .onDelete(perform: $solarSystem.remove)
    }.navigationBarItems(trailing:
      Button("Add") {
        $solarSystems.append(SolarSystem())
      }
    )
  }
}
```

## Fully Encrypted
Data can be encrypted in-flight and at-rest, keeping even the most sensitive data secure.
```swift
// Generate a random encryption key
var key = Data(count: 64)
_ = key.withUnsafeMutableBytes { bytes in
  SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
}

// Add the encryption key to the config and open the Cosmoverse
let config = Cosmoverse.Configuration(encryptionKey: key)
let stage = try Usd.Stage(configuration: config)

// Use the stage as normal
let worlds = stage.traverse(World.self).filter("name contains 'Earth'")
```
