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

    override func setUp() async throws {
        feed = try Snap.store.feed("feed_default")
        longFeed = try Snap.store.feed("feed_long_headlines")
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

    // MARK: Helpers

    private func teaser(_ id: String, in feed: Feed) throws -> Teaser {
        for case .teaser(let teaser) in feed.items where teaser.id == id { return teaser }
        throw XCTSkip("teaser \(id) missing from fixture")
    }
}
