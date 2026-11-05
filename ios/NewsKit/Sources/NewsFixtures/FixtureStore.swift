import Foundation
import NewsCore
import UIKit

/// Loads the shared, cross-platform fixtures in `/fixtures` (the same files Android uses).
public struct FixtureStore: Sendable {
    public let root: URL

    public init(root: URL) { self.root = root }

    /// Tests: resolve `<repo>/fixtures` relative to this source file (works on simulators, which share the host FS).
    public static func repository(file: StaticString = #filePath) -> FixtureStore {
        var url = URL(fileURLWithPath: "\(file)")
        // .../ios/NewsKit/Sources/NewsFixtures/FixtureStore.swift -> repo root (5 levels up)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return FixtureStore(root: url.appendingPathComponent("fixtures"))
    }

    /// App mock mode: fixtures are bundled as a folder reference named "fixtures".
    public static func bundled(_ bundle: Bundle = .main) -> FixtureStore? {
        bundle.url(forResource: "fixtures", withExtension: nil).map(FixtureStore.init(root:))
    }

    public func feed(_ name: String) throws -> Feed {
        let data = try Data(contentsOf: root.appendingPathComponent("feed/\(name).json"))
        return try NewsDecoder.make().decode(Feed.self, from: data)
    }

    public func image(_ name: String) -> UIImage? {
        UIImage(contentsOfFile: root.appendingPathComponent("images/\(name)").path)
    }

    /// A FeedClient that serves a named fixture — the mocked network layer.
    public func client(_ name: String) -> FeedClient {
        let store = self
        return FeedClient { try store.feed(name) }
    }
}

/// Fixed values every deterministic render uses (documented in fixtures/README.md).
public enum FixtureEnvironment {
    public static let now = Date(timeIntervalSince1970: 1_793_888_000) // 2026-11-05T14:13:20Z (headlines fetched that day)
    public static let locale = Locale(identifier: "de_DE")
    public static let timeZone = TimeZone(identifier: "Europe/Berlin")!
}
