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
