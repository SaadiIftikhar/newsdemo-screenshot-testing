import Account
import AppShell
import NewsCore
import NewsFixtures
import NewsUI
import SwiftUI

/// Thin app shell. Launch arguments pick the data source and starting screen, so manual QA and
/// Layer 2 (Maestro) can open any state directly:
///   (no args)                      -> bundled fixture "feed_default", Nachrichten tab
///   -fixture feed_long_headlines   -> any shared fixture
///   -offline                       -> simulate no connectivity
///   -baseURL http://localhost:8080 -> live HTTP client, e.g. against a WireMock serving /fixtures
///   -tab games | account           -> start on another tab
///   -signedIn                      -> start logged in as the demo user
@main
struct NewsDemoApp: App {
    private let feedViewModel: FeedViewModel
    private let accountModel: AccountViewModel
    private let imageProvider: ImageProvider
    private let initialTab: AppTab
    /// Fixture mode pins the clock + zone too, so Layer 2 screenshots are deterministic.
    private let now: Date?
    private let timeZone: TimeZone

    init() {
        let defaults = UserDefaults.standard // launch arguments land here: -key value
        let arguments = ProcessInfo.processInfo.arguments
        let fixtures = FixtureStore.bundled()
        let usesFixtures = defaults.string(forKey: "baseURL") == nil
        now = usesFixtures ? FixtureEnvironment.now : nil
        timeZone = usesFixtures ? FixtureEnvironment.timeZone : .current
        initialTab = defaults.string(forKey: "tab").flatMap(AppTab.init(rawValue:)) ?? .feed

        if arguments.contains("-offline") {
            feedViewModel = FeedViewModel(client: .failing(.offline))
        } else if let base = defaults.string(forKey: "baseURL").flatMap(URL.init(string:)) {
            feedViewModel = FeedViewModel(client: .live(baseURL: base))
        } else if let fixtures {
            feedViewModel = FeedViewModel(client: fixtures.client(defaults.string(forKey: "fixture") ?? "feed_default"))
        } else {
            feedViewModel = FeedViewModel(client: .failing(.server(status: 500)))
        }

        let demoUser = UserProfile(name: "Demo Leser", email: AuthClient.demoEmail, isPremium: true)
        accountModel = AccountViewModel(client: .demo, state: arguments.contains("-signedIn") ? .signedIn(demoUser) : .signedOut)

        if let fixtures {
            imageProvider = .local { fixtures.image($0) }
        } else {
            imageProvider = .remote(baseURL: URL(string: "https://cdn.example.com/img/")!)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(feedViewModel: feedViewModel, accountModel: accountModel, initialTab: initialTab)
                .environment(\.imageProvider, imageProvider)
                // German-language product: never format with the device locale. On an en_US device the
                // 12-hour preference leaked in ("11:05 PM Uhr"). Found by running the real app, not by
                // snapshots (those pin de_DE): the reason Layer 2 exists.
                .environment(\.locale, Locale(identifier: "de_DE"))
                .environment(\.timeZone, timeZone)
                .environment(\.now, now ?? Date())
        }
    }
}
