// swift-tools-version: 6.0
import PackageDescription

// NewsKit mirrors how a large modular app is usually split:
//  - NewsCore:     models, decoding, the FeedClient network seam (no UI)
//  - NewsUI:       design-system components + feed screen (production UI under test)
//  - NewsFixtures: loads the shared /fixtures JSON + images; used by tests and the app's mock mode
let package = Package(
    name: "NewsKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NewsCore", targets: ["NewsCore"]),
        .library(name: "NewsUI", targets: ["NewsUI"]),
        .library(name: "NewsFixtures", targets: ["NewsFixtures"]),
    ],
    dependencies: [
        // Pinned exactly: a snapshot library bump can change rendering/diffing, so it is a deliberate PR.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.7"),
    ],
    targets: [
        .target(name: "NewsCore"),
        .target(name: "NewsUI", dependencies: ["NewsCore"]),
        .target(name: "NewsFixtures", dependencies: ["NewsCore"]),
        .testTarget(
            name: "NewsCoreTests",
            dependencies: ["NewsCore", "NewsFixtures"]
        ),
        .testTarget(
            name: "NewsUISnapshotTests",
            dependencies: [
                "NewsUI",
                "NewsFixtures",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),
    ]
)
