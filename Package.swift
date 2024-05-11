// swift-tools-version:5.10

import Foundation
import PackageDescription

let coreVersion = Version("14.6.2")
let cocoaVersion = Version("10.50.0")

let package = Package(
  name: "Realm",
  platforms: [
    .macOS(.v10_13),
    .iOS(.v12),
    .tvOS(.v12),
    .watchOS(.v4),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "Realm",
      type: .dynamic,
      targets: ["Realm"]
    ),
    .library(
      name: "RealmSwift",
      type: .dynamic,
      targets: ["RealmSwift"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/realm/realm-core.git", exact: coreVersion)
  ],
  targets: [
    .target(
      name: "Realm",
      dependencies: [.product(name: "RealmCore", package: "realm-core")],
      exclude: [
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "Carthage",
        "Configuration",
        "LICENSE",
        "Package.swift",
        "README.md",
        "Realm.podspec",
        "Realm.xcodeproj",
        "Realm/ObjectServerTests",
        "Realm/Realm-Info.plist",
        "Realm/Swift/RLMSupport.swift",
        "Realm/TestUtils",
        "Realm/Tests",
        "RealmSwift",
        "RealmSwift.podspec",
        "SUPPORT.md",
        "build.sh",
        "ci_scripts/ci_post_clone.sh",
        "contrib",
        "dependencies.list",
        "docs",
        "examples",
        "include",
        "logo.png",
        "plugin",
        "scripts",
      ],
      sources: [
        "Realm/RLMAccessor.mm",
        "Realm/RLMAnalytics.mm",
        "Realm/RLMArray.mm",
        "Realm/RLMAsymmetricObject.mm",
        "Realm/RLMAsyncTask.mm",
        "Realm/RLMClassInfo.mm",
        "Realm/RLMCollection.mm",
        "Realm/RLMConstants.m",
        "Realm/RLMDecimal128.mm",
        "Realm/RLMDictionary.mm",
        "Realm/RLMEmbeddedObject.mm",
        "Realm/RLMError.mm",
        "Realm/RLMEvent.mm",
        "Realm/RLMGeospatial.mm",
        "Realm/RLMLogger.mm",
        "Realm/RLMManagedArray.mm",
        "Realm/RLMManagedDictionary.mm",
        "Realm/RLMManagedSet.mm",
        "Realm/RLMMigration.mm",
        "Realm/RLMObject.mm",
        "Realm/RLMObjectBase.mm",
        "Realm/RLMObjectId.mm",
        "Realm/RLMObjectSchema.mm",
        "Realm/RLMObjectStore.mm",
        "Realm/RLMObservation.mm",
        "Realm/RLMPredicateUtil.mm",
        "Realm/RLMProperty.mm",
        "Realm/RLMQueryUtil.mm",
        "Realm/RLMRealm.mm",
        "Realm/RLMRealmConfiguration.mm",
        "Realm/RLMRealmUtil.mm",
        "Realm/RLMResults.mm",
        "Realm/RLMScheduler.mm",
        "Realm/RLMSchema.mm",
        "Realm/RLMSectionedResults.mm",
        "Realm/RLMSet.mm",
        "Realm/RLMSwiftCollectionBase.mm",
        "Realm/RLMSwiftSupport.m",
        "Realm/RLMSwiftValueStorage.mm",
        "Realm/RLMThreadSafeReference.mm",
        "Realm/RLMUUID.mm",
        "Realm/RLMUpdateChecker.mm",
        "Realm/RLMUtil.mm",
        "Realm/RLMValue.mm",

        // Sync source files
        "Realm/NSError+RLMSync.m",
        "Realm/RLMApp.mm",
        "Realm/RLMAPIKeyAuth.mm",
        "Realm/RLMBSON.mm",
        "Realm/RLMCredentials.mm",
        "Realm/RLMEmailPasswordAuth.mm",
        "Realm/RLMFindOneAndModifyOptions.mm",
        "Realm/RLMFindOptions.mm",
        "Realm/RLMInitialSubscriptionsConfiguration.m",
        "Realm/RLMMongoClient.mm",
        "Realm/RLMMongoCollection.mm",
        "Realm/RLMNetworkTransport.mm",
        "Realm/RLMProviderClient.mm",
        "Realm/RLMPushClient.mm",
        "Realm/RLMRealm+Sync.mm",
        "Realm/RLMSyncConfiguration.mm",
        "Realm/RLMSyncManager.mm",
        "Realm/RLMSyncSession.mm",
        "Realm/RLMSyncSubscription.mm",
        "Realm/RLMSyncUtil.mm",
        "Realm/RLMUpdateResult.mm",
        "Realm/RLMUser.mm",
        "Realm/RLMUserAPIKey.mm"
      ],
      resources: [
        .copy("Realm/PrivacyInfo.xcprivacy")
      ],
      publicHeadersPath: "include",
      cxxSettings: [
        .headerSearchPath("."),
        .headerSearchPath("include"),
        .define("REALM_SPM", to: "1"),
        .define("REALM_ENABLE_SYNC", to: "1"),
        .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersion)\""),
        .define("REALM_VERSION", to: "\"\(coreVersion)\""),
        .define("REALM_IOPLATFORMUUID", to: "@\"\(runCommand())\""),

        .define("REALM_DEBUG", .when(configuration: .debug)),
        .define("REALM_NO_CONFIG"),
        .define("REALM_INSTALL_LIBEXECDIR", to: ""),
        .define("REALM_ENABLE_ASSERTIONS", to: "1"),
        .define("REALM_ENABLE_ENCRYPTION", to: "1"),

        .define("REALM_VERSION_MAJOR", to: String(coreVersion.major)),
        .define("REALM_VERSION_MINOR", to: String(coreVersion.minor)),
        .define("REALM_VERSION_PATCH", to: String(coreVersion.patch)),
        .define("REALM_VERSION_EXTRA", to: "\"\(coreVersion.prereleaseIdentifiers.first ?? "")\""),
        .define("REALM_VERSION_STRING", to: "\"\(coreVersion)\""),
        .define("REALM_ENABLE_GEOSPATIAL", to: "1"),
      ],
      linkerSettings: [
        .linkedFramework("UIKit", .when(platforms: [.iOS, .macCatalyst, .tvOS, .watchOS]))
      ]
    ),
    .target(
      name: "RealmSwift",
      dependencies: ["Realm"],
      exclude: [
        "Nonsync.swift",
        "RealmSwift-Info.plist",
        "Tests",
      ],
      resources: [
        .copy("PrivacyInfo.xcprivacy")
      ]
    ),
    .target(
      name: "RealmTestSupport",
      dependencies: ["Realm"],
      path: "Realm/TestUtils",
      cxxSettings: [
        .headerSearchPath("Realm"),
        .headerSearchPath(".."),
      ]
    ),
    .target(
      name: "RealmSwiftTestSupport",
      dependencies: ["RealmSwift", "RealmTestSupport"],
      path: "RealmSwift/Tests",
      sources: ["TestUtils.swift"]
    ),
    .testTarget(
      name: "RealmTests",
      dependencies: ["Realm", "RealmTestSupport"],
      path: "Realm/Tests",
      exclude: [
        "PrimitiveArrayPropertyTests.tpl.m",
        "PrimitiveDictionaryPropertyTests.tpl.m",
        "PrimitiveRLMValuePropertyTests.tpl.m",
        "PrimitiveSetPropertyTests.tpl.m",
        "RealmTests-Info.plist",
        "Swift",
        "SwiftUITestHost",
        "SwiftUITestHostUITests",
        "TestHost",
        "array_tests.py",
        "dictionary_tests.py",
        "fileformat-pre-null.realm",
        "mixed_tests.py",
        "set_tests.py",
        "SwiftUISyncTestHost",
        "SwiftUISyncTestHostUITests"
      ],
      cxxSettings: [
        .headerSearchPath("Realm"),
        .headerSearchPath(".."),
      ]
    ),
    .testTarget(
      name: "RealmObjcSwiftTests",
      dependencies: ["Realm", "RealmTestSupport"],
      path: "Realm/Tests/Swift",
      exclude: ["RealmObjcSwiftTests-Info.plist"]
    ),
    .testTarget(
      name: "RealmSwiftTests",
      dependencies: ["RealmSwift", "RealmTestSupport", "RealmSwiftTestSupport"],
      path: "RealmSwift/Tests",
      exclude: [
        "RealmSwiftTests-Info.plist",
        "QueryTests.swift.gyb",
        "TestUtils.swift"
      ]
    ),
    .testTarget(
      name: "ObjectServerTests",
      dependencies: ["RealmSwift", "RealmTestSupport", "RealmSyncTestSupport", "RealmSwiftSyncTestSupport"],
      exclude: [],
      sources: [
        "AsyncSyncTests.swift",
        "ClientResetTests.swift",
        "CombineSyncTests.swift",
        "EventTests.swift",
        "SwiftAsymmetricSyncServerTests.swift",
        "SwiftCollectionSyncTests.swift",
        "SwiftFlexibleSyncServerTests.swift",
        "SwiftMongoClientTests.swift",
        "SwiftObjectServerPartitionTests.swift",
        "SwiftObjectServerTests.swift",
        "SwiftUIServerTests.swift",
      ],
      cxxSettings: [
        .headerSearchPath("Realm"),
        .headerSearchPath(".."),
      ]
    )
  ],
  cxxLanguageStandard: .cxx20
)

func runCommand() -> String
{
  let task = Process()
  let pipe = Pipe()

  task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioregg")
  task.arguments = ["-rd1", "-c", "IOPlatformExpertDevice"]
  task.standardInput = nil
  task.standardError = nil
  task.standardOutput = pipe
  do
  {
    try task.run()
  }
  catch
  {
    return ""
  }

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(data: data, encoding: .utf8) ?? ""
  let range = NSRange(output.startIndex..., in: output)
  guard let regex = try? NSRegularExpression(pattern: ".*\\\"IOPlatformUUID\\\"\\s=\\s\\\"(.+)\\\"", options: .caseInsensitive),
        let firstMatch = regex.matches(in: output, range: range).first
  else
  {
    return ""
  }

  let matches = (0 ..< firstMatch.numberOfRanges).compactMap
  { ind -> String? in
    let matchRange = firstMatch.range(at: ind)
    if matchRange != range,
       let substringRange = Range(matchRange, in: output)
    {
      let capture = String(output[substringRange])
      return capture
    }
    return nil
  }
  return matches.last ?? ""
}
