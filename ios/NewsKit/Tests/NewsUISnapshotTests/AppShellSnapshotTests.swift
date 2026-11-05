import Account
import AppShell
import Games
import NewsCore
import NewsFixtures
import NewsUI
import SnapshotTesting
import SwiftUI
import XCTest

/// The 3-tab app shell, including the floating tab bar.
@MainActor
final class AppShellSnapshotTests: XCTestCase {
    private func root(_ tab: AppTab, account: AccountViewModel = AccountViewModel()) async throws -> RootView {
        let feed = FeedViewModel(client: Snap.store.client("feed_default"))
        await feed.load()
        return RootView(feedViewModel: feed, accountModel: account, initialTab: tab)
    }

    func test_appShell_feedTab() async throws {
        assertScreen(try await root(.feed), variants: [.light, .dark])
    }

    func test_appShell_gamesTab() async throws {
        assertScreen(try await root(.games), variants: [.light])
    }

    func test_appShell_accountTab() async throws {
        assertScreen(try await root(.account), variants: [.light])
    }
}
