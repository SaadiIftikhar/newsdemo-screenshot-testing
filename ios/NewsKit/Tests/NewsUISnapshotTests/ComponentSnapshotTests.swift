import NewsCore
import NewsFixtures
import NewsUI
import SnapshotTesting
import SwiftUI
import XCTest

/// Component-level snapshots: each design-system piece in the states that matter, from shared fixtures.
@MainActor
final class ComponentSnapshotTests: XCTestCase {
    private var feed: Feed!
    private var longFeed: Feed!
    private var edge: Feed!

    override func setUp() async throws {
        feed = try Snap.store.feed("feed_default")
        longFeed = try Snap.store.feed("feed_long_headlines")
        edge = try Snap.store.feed("feed_edge_cases")
    }

    // MARK: Breaking news banner

    func test_breakingBanner_default() throws {
        assertComponent(BreakingNewsBanner(news: try XCTUnwrap(feed.breaking)))
    }

    func test_breakingBanner_longHeadline() throws {
        assertComponent(BreakingNewsBanner(news: try XCTUnwrap(longFeed.breaking)), variants: [.light, .largeText])
    }

    // MARK: Teaser cards

    func test_teaserCard_withImage() throws {
        assertComponent(TeaserCard(teaser: try teaser("tsr-001", in: feed)))
    }

    func test_teaserCard_withoutImage() throws {
        assertComponent(TeaserCard(teaser: try teaser("tsr-003", in: feed)), variants: [.light, .dark])
    }

    /// WELT-style paywalled item: the PLUS badge must survive refactors in both themes.
    func test_teaserCard_premium() throws {
        assertComponent(TeaserCard(teaser: try teaser("tsr-002", in: feed)))
    }

    func test_teaserCard_premium_longHeadline() throws {
        assertComponent(TeaserCard(teaser: try teaser("tsr-101", in: longFeed)), variants: [.light, .largeText])
    }

    // MARK: Live ticker / video / ad

    func test_liveTicker_default() throws {
        guard case .liveTicker(let ticker) = try XCTUnwrap(feed.items.first(where: { $0.id == "live-001" })) else {
            return XCTFail("fixture changed")
        }
        assertComponent(LiveTickerCard(ticker: ticker))
    }

    func test_videoTeaser_default() throws {
        guard case .video(let video) = try XCTUnwrap(feed.items.first(where: { $0.id == "vid-001" })) else {
            return XCTFail("fixture changed")
        }
        assertComponent(VideoTeaserCard(video: video), variants: [.light, .dark])
    }

    func test_adSlot_placeholder() throws {
        guard case .ad(let slot) = try XCTUnwrap(feed.items.first(where: { $0.id == "ad-001" })) else {
            return XCTFail("fixture changed")
        }
        assertComponent(AdSlotView(slot: slot), variants: [.light, .dark])
    }

    // MARK: Edge states (feed_edge_cases.json)

    func test_liveTicker_ended() throws {
        guard case .liveTicker(let ticker) = try XCTUnwrap(edge.items.first(where: { $0.id == "live-201" })) else {
            return XCTFail("fixture changed")
        }
        assertComponent(LiveTickerCard(ticker: ticker), variants: [.light, .dark])
    }

    /// The image fails to load: the placeholder must look intentional, not broken.
    func test_teaserCard_imageMissing() throws {
        assertComponent(TeaserCard(teaser: try teaser("tsr-201", in: edge)), variants: [.light])
    }

    // MARK: Helpers

    /// FAILS (never skips) when the fixture lost an id: a skipped premium test would leave the PLUS badge unguarded.
    private func teaser(_ id: String, in feed: Feed) throws -> Teaser {
        for case .teaser(let teaser) in feed.items where teaser.id == id { return teaser }
        return try XCTUnwrap(nil as Teaser?, "teaser \(id) missing from fixture")
    }
}
