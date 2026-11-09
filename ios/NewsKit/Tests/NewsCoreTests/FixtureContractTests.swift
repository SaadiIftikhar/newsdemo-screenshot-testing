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

    /// Every image any fixture references exists under EXACTLY that file name. iOS's UIImage(contentsOfFile:)
    /// silently found "politics" for "politics.png" while Android showed the placeholder: compare names, not loads.
    /// `missing-image.png` is the one deliberate exception (the broken-image state in feed_edge_cases).
    func test_everyReferencedImageExists_withItsExactFileName() throws {
        let files = try FileManager.default.contentsOfDirectory(atPath: store.root.appendingPathComponent("images").path)
        let fixtures = try FileManager.default.contentsOfDirectory(atPath: store.root.appendingPathComponent("feed").path)
        for fixture in fixtures where fixture.hasSuffix(".json") {
            let feed = try store.feed(String(fixture.dropLast(5)))
            for item in feed.items {
                let name: String? = switch item {
                case .teaser(let t): t.image
                case .video(let v): v.image
                default: nil
                }
                guard let name, name != "missing-image.png" else { continue }
                XCTAssertTrue(files.contains(name), "\(fixture): image \"\(name)\" is not a file in fixtures/images")
            }
        }
    }
}
