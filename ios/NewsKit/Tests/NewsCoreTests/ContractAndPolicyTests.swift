import Account
import NewsCore
import NewsFixtures
import NewsUI
import UIKit
import XCTest

/// Contract for messy backend data: the exact items and flags a decoder must produce. Written as a literal so any
/// other client (e.g. an Android app) can assert the same expectations. Before this contract, one missing `premium`
/// field failed the whole feed in one decoder and silently made a PLUS article free in another.
final class EdgeCaseDecodingContractTests: XCTestCase {
    func test_edgeCases_decodeToTheContractedItems() throws {
        let feed = try FixtureStore.repository().feed("feed_edge_cases")
        XCTAssertNil(feed.breaking)
        XCTAssertEqual(feed.items.map(\.id), ["live-201", "tsr-201", "ad-201", "tsr-202", "tsr-203"])

        guard case .liveTicker(let ticker) = feed.items[0], case .teaser(let free) = feed.items[1],
              case .ad(let ad) = feed.items[2], case .teaser(let archive) = feed.items[3],
              case .teaser(let fractional) = feed.items[4] else { return XCTFail("unexpected item types") }
        XCTAssertFalse(ticker.isLive)
        XCTAssertFalse(free.isPremium, "missing `premium` means free, not a decoding error")
        XCTAssertEqual(free.kicker, "TESTFALL", "duplicate id: the first entry wins")
        XCTAssertFalse(ad.filled)
        XCTAssertEqual(ad.height, 250.5)
        XCTAssertTrue(archive.isPremium)
        XCTAssertEqual(fractional.publishedAt.timeIntervalSince1970, 1_793_884_460.5, accuracy: 0.001)
    }
}

/// What each golden MEANS. If someone edits a fixture so "the premium teaser" is no longer premium, a re-record
/// would approve a premium golden without a badge. These tests fail first.
final class FixturePreconditionTests: XCTestCase {
    func test_snapshotFixturesStillMeanWhatTheTestsAssume() throws {
        let store = FixtureStore.repository()
        let main = try store.feed("feed_default")
        let long = try store.feed("feed_long_headlines")
        func teaser(_ id: String, _ feed: Feed) throws -> Teaser {
            for case .teaser(let t) in feed.items where t.id == id { return t }
            return try XCTUnwrap(nil as Teaser?, "\(id) missing")
        }
        XCTAssertNotNil(main.breaking)
        XCTAssertTrue(try teaser("tsr-002", main).isPremium, "test_teaserCard_premium needs a PLUS teaser")
        XCTAssertTrue(try teaser("tsr-101", long).isPremium)
        XCTAssertNotNil(try teaser("tsr-001", main).image, "test_teaserCard_withImage needs an image")
        XCTAssertNil(try teaser("tsr-003", main).image, "test_teaserCard_withoutImage needs no image")
        XCTAssertTrue(main.items.contains { $0.id == "live-001" } && main.items.contains { $0.id == "vid-001" }
                      && main.items.contains { $0.id == "ad-001" })
    }
}

final class PaywallPolicyTests: XCTestCase {
    let url = URL(string: "https://www.welt.de/plus")!

    func test_freeArticlesAlwaysOpen() {
        for entitlement in [Entitlement.anonymous, .registered, .subscriber] {
            XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: false, entitlement: entitlement), .open(url))
        }
    }

    func test_plusArticlesOpenOnlyForSubscribers() {
        XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: true, entitlement: .anonymous), .paywall(url))
        XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: true, entitlement: .registered), .paywall(url))
        XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: true, entitlement: .subscriber), .open(url))
    }

    @MainActor
    func test_entitlementFollowsTheAccount() async {
        let model = AccountViewModel(client: .demo, email: AuthClient.basicEmail, password: AuthClient.demoPassword)
        XCTAssertEqual(model.entitlement, .anonymous)
        await model.signIn()
        XCTAssertEqual(model.entitlement, .registered)
        let plus = AccountViewModel(client: .demo, email: AuthClient.demoEmail, password: AuthClient.demoPassword)
        await plus.signIn()
        XCTAssertEqual(plus.entitlement, .subscriber)
    }
}

/// Every branch of the timestamp formatter, including a hostile device locale (the "11:05 PM Uhr" bug).
final class DateFormatterTests: XCTestCase {
    let now = FixtureEnvironment.now
    let berlin = FixtureEnvironment.timeZone

    func test_relativeBranches() {
        XCTAssertEqual(NewsDateFormatter.relative(now.addingTimeInterval(-20), now: now, timeZone: berlin), "gerade eben")
        XCTAssertEqual(NewsDateFormatter.relative(now.addingTimeInterval(-9 * 60), now: now, timeZone: berlin), "vor 9 Min.")
        XCTAssertEqual(NewsDateFormatter.relative(now.addingTimeInterval(-5 * 3600), now: now, timeZone: berlin), "vor 5 Std.")
    }

    func test_olderThanADay_isGerman24h_evenWithAnEnglishDeviceLocale() {
        let date = Date(timeIntervalSince1970: 1_793_607_600) // 2026-11-02T08:20:00Z = 09:20 Berlin
        let text = NewsDateFormatter.relative(date, now: now, locale: Locale(identifier: "en_US"), timeZone: berlin)
        XCTAssertEqual(text, "02.11.2026, 09:20 Uhr")
        XCTAssertFalse(text.contains("AM") || text.contains("PM"))
    }
}
