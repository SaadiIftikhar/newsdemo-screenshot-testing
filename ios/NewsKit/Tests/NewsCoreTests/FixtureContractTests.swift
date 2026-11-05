import NewsCore
import NewsFixtures
import XCTest

/// Guards the fixtures themselves: if a fixture stops decoding, every snapshot built on it is meaningless.
final class FixtureContractTests: XCTestCase {
    let store = FixtureStore.repository()

    func test_allFeedFixturesDecode() throws {
        let dir = store.root.appendingPathComponent("feed")
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".json") }
        XCTAssertFalse(files.isEmpty)
        for file in files {
            XCTAssertNoThrow(try store.feed(String(file.dropLast(5))), "\(file) must decode with the production decoder")
        }
    }

    func test_unknownItemTypesAreDropped() throws {
        let feed = try store.feed("feed_default")
        XCTAssertFalse(feed.items.contains(.unsupported))
        XCTAssertEqual(feed.items.count, 6)
    }

    func test_everyReferencedImageExists() throws {
        let feed = try store.feed("feed_default")
        let names: [String] = feed.items.compactMap {
            switch $0 {
            case .teaser(let t): t.image
            case .video(let v): v.image
            default: nil
            }
        }
        for name in names { XCTAssertNotNil(store.image(name), "missing fixture image \(name)") }
    }
}
