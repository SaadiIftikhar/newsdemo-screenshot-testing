// swift-tools-version: 6.0
import PackageDescription

// NewsKit mirrors how a large modular app is usually split:
//  - NewsCore:     models, decoding, the FeedClient network seam (no UI)
//  - NewsUI:       design-system components + feed screen (production UI under test)
//  - Games:        game rules (pure, unit-tested) + game screens
//  - Account:      login / profile screens on top of the AuthClient seam
//  - AppShell:     the 3-tab root (feed, games, account) + in-app browser for articles
//  - NewsFixtures: loads the shared /fixtures JSON + images; used by tests and the app's mock mode
let package = Package(
    name: "NewsKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NewsCore", targets: ["NewsCore"]),
        .library(name: "NewsUI", targets: ["NewsUI"]),
        .library(name: "NewsFixtures", targets: ["NewsFixtures"]),
        .library(name: "Games", targets: ["Games"]),
        .library(name: "Account", targets: ["Account"]),
        .library(name: "AppShell", targets: ["AppShell"]),
    ],
    dependencies: [
        // Pinned exactly: a snapshot library bump can change rendering/diffing, so it is a deliberate PR.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.7"),
    ],
    targets: [
        .target(name: "NewsCore"),
        .target(name: "NewsUI", dependencies: ["NewsCore"]),
        .target(name: "NewsFixtures", dependencies: ["NewsCore"]),
        .target(name: "Games", dependencies: ["NewsUI"]),
        .target(name: "Account", dependencies: ["NewsCore", "NewsUI"]),
        .target(name: "AppShell", dependencies: ["NewsCore", "NewsUI", "Games", "Account"]),
        .testTarget(
            name: "NewsCoreTests",
            dependencies: ["NewsCore", "NewsFixtures", "NewsUI", "Games", "Account"]
        ),
        .testTarget(
            name: "NewsUISnapshotTests",
            dependencies: [
                "NewsUI",
                "NewsFixtures",
                "Games",
                "Account",
                "AppShell",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),
    ]
)
