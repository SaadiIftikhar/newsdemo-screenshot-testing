import NewsCore
import NewsFixtures
import NewsUI
import SnapshotTesting
import SwiftUI
import XCTest

/// Screen-level snapshots: the whole feed in each data/error state, on fixed device geometries.
@MainActor
final class FeedScreenSnapshotTests: XCTestCase {

    func test_feed_default() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_default"))))
    }

    /// The whole feed, not just the first screen: card spacing, ad placement and the last item are protected too.
    func test_feed_default_fullHeight() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_default"))),
                     device: .iPhone13FullHeight, variants: [.light, .dark])
    }

    /// WELT Edition is read on tablets: the feed column is capped instead of stretching edge to edge.
    func test_feed_default_tablet() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_default"))),
                     device: .iPadPro11(.portrait), variants: [.light])
    }

    /// Malformed items dropped, ad without fill collapsed, ended ticker, broken image, >24 h and "gerade eben".
    func test_feed_edgeCases() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_edge_cases"))),
                     device: .iPhone13FullHeight, variants: [.light])
    }

    /// Messy CMS text (HTML entities, stray line breaks, soft hyphens, emoji, non-Latin names), a ticker before its
    /// first entry, a video longer than an hour and a timestamp in the future. Full length and at the largest text
    /// size, where long German words have to break.
    func test_feed_hostileContent() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_hostile_content"))),
                     device: .iPhone13FullHeight, variants: [.light, .largeText])
    }

    /// Offline after a successful load: the cached feed stays on screen with "Stand 15:02 Uhr" on top,
    /// instead of an error screen replacing the news.
    func test_feed_offlineCached() throws {
        let since = FixtureEnvironment.now.addingTimeInterval(-11 * 60)
        assertScreen(FeedView(state: .stale(try Snap.store.feed("feed_default"), since: since, reason: .offline)),
                     variants: [.light, .dark])
    }

    /// Server error on refresh, content loaded yesterday: the notice shows the full date.
    func test_feed_refreshFailed() throws {
        let since = FixtureEnvironment.now.addingTimeInterval(-24 * 3600)
        assertScreen(FeedView(state: .stale(try Snap.store.feed("feed_default"), since: since, reason: .server(status: 503))),
                     variants: [.light])
    }

    func test_feed_loading() {
        assertScreen(FeedView(state: .loading), variants: [.light, .dark])
    }

    /// Smallest supported phone: catches layouts that only break on narrow screens.
    func test_feed_default_smallDevice() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_default"))),
                     device: .iPhoneSe, variants: [.light])
    }

    func test_feed_longHeadlines() throws {
        assertScreen(FeedView(state: .loaded(try Snap.store.feed("feed_long_headlines"))),
                     variants: [.light, .largeText])
    }

    func test_feed_empty() {
        assertScreen(FeedView(state: .empty), variants: [.light, .dark])
    }

    func test_feed_offline() {
        assertScreen(FeedView(state: .failed(.offline)), variants: [.light, .dark])
    }

    func test_feed_serverError() {
        assertScreen(FeedView(state: .failed(.server(status: 503))), variants: [.light])
    }

    /// End-to-end through the production seam: real FeedScreen + real view model,
    /// with only the network client swapped for a fixture-backed one.
    func test_feedScreen_viaViewModel_mockedClient() async throws {
        let viewModel = FeedViewModel(client: Snap.store.client("feed_default"))
        await viewModel.load()
        assertScreen(FeedScreen(viewModel: viewModel), variants: [.light])
    }

    func test_feedScreen_viaViewModel_offlineClient() async throws {
        let viewModel = FeedViewModel(client: .failing(.offline))
        await viewModel.load()
        assertScreen(FeedScreen(viewModel: viewModel), variants: [.light])
    }
}
