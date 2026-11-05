import NewsCore
import NewsFixtures
import NewsUI
import SwiftUI

/// Thin app shell. The data source is chosen at launch — the same seam serves three purposes:
///   (no args)                     -> bundled fixture "feed_default" (this demo has no real backend)
///   -fixture feed_long_headlines  -> any shared fixture (used by Maestro / manual QA, Layer 2)
///   -baseURL http://localhost:8080 -> live HTTP client, e.g. against a WireMock serving /fixtures
///   -offline                      -> simulate no connectivity
@main
struct NewsDemoApp: App {
    private let viewModel: FeedViewModel
    private let imageProvider: ImageProvider

    init() {
        let defaults = UserDefaults.standard // launch arguments land here: -key value
        let fixtures = FixtureStore.bundled()

        if ProcessInfo.processInfo.arguments.contains("-offline") {
            viewModel = FeedViewModel(client: .failing(.offline))
        } else if let base = defaults.string(forKey: "baseURL").flatMap(URL.init(string:)) {
            viewModel = FeedViewModel(client: .live(baseURL: base))
        } else if let fixtures {
            viewModel = FeedViewModel(client: fixtures.client(defaults.string(forKey: "fixture") ?? "feed_default"))
        } else {
            viewModel = FeedViewModel(client: .failing(.server(status: 500)))
        }

        if let fixtures {
            imageProvider = .local { fixtures.image($0) }
        } else {
            imageProvider = .remote(baseURL: URL(string: "https://cdn.example.com/img/")!)
        }
    }

    var body: some Scene {
        WindowGroup {
            FeedScreen(viewModel: viewModel)
                .environment(\.imageProvider, imageProvider)
        }
    }
}
