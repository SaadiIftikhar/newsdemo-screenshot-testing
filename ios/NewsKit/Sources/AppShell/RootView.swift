import Account
import Games
import NewsCore
import NewsUI
import SafariServices
import SwiftUI

public enum AppTab: String, Hashable, Sendable, CaseIterable {
    case feed, games, account

    var title: String {
        switch self {
        case .feed: "Nachrichten"
        case .games: "Spiele"
        case .account: "Konto"
        }
    }

    var icon: String {
        switch self {
        case .feed: "newspaper"
        case .games: "gamecontroller"
        case .account: "person.crop.circle"
        }
    }
}

/// App root: three tabs behind our own floating tab bar.
///
/// Why not the system `TabView` in this demo? On iOS 26 its floating "Liquid Glass" bar is not captured by
/// in-process snapshots (the glass renders blank, lazy tab content isn't laid out before capture). For a demo
/// whose point is screenshot coverage, a custom bar keeps every pixel testable.
/// In a production app we would NOT change product UI for a test tool: keep the system bar, snapshot the tab
/// *content*, and cover the system chrome in Layer 2 (XCUITest/Maestro on a real simulator). See STRATEGY.md.
public struct RootView: View {
    @State private var selection: AppTab
    private let feedViewModel: FeedViewModel
    private let accountModel: AccountViewModel
    /// Game boards live here, not in the views: only the selected tab is in the hierarchy (see body).
    @State private var games: GamesModel
    @State private var presented: Presented?

    public init(feedViewModel: FeedViewModel, accountModel: AccountViewModel,
                initialTab: AppTab = .feed, gamesPath: [GameKind] = []) {
        self.feedViewModel = feedViewModel
        self.accountModel = accountModel
        _games = State(initialValue: GamesModel(path: gamesPath))
        _selection = State(initialValue: initialTab)
    }

    public var body: some View {
        ZStack {
            // Only the selected tab is in the hierarchy. Hidden-but-alive tabs (opacity 0) stayed reachable for
            // VoiceOver even with `.accessibilityHidden` (the feed heading and the login fields, found by the
            // accessibility audit). State survives a switch because it lives in models owned here and above:
            // feed, account and game boards. Known trade-off: the feed's scroll position resets.
            switch selection {
            case .feed: FeedScreen(viewModel: feedViewModel, onOpenArticle: open)
            case .games: GamesHome(model: games)
            case .account: AccountScreen(model: accountModel)
            }
        }
        // Scrollable content can scroll *under* the floating bar but always ends above it.
        .contentMargins(.bottom, FloatingTabBar.reservedHeight, for: .scrollContent)
        .overlay(alignment: .bottom) { FloatingTabBar(selection: $selection) }
        .sheet(item: $presented) { item in
            switch item {
            case .article(let url):
                SafariView(url: url).ignoresSafeArea()
            case .paywall:
                PaywallView(entitlement: accountModel.entitlement,
                            onSubscribe: { presented = nil },
                            onSignIn: { presented = nil; selection = .account },
                            onClose: { presented = nil })
            }
        }
        // A keyboard left up in the (still alive, hidden) Konto tab must not cover the next tab.
        .onChange(of: selection) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    /// Free articles open in the in-app browser; PLUS articles only for subscribers, otherwise the paywall.
    private func open(_ request: ArticleRequest) {
        // SFSafariViewController throws on non-web schemes: only http(s) is ever opened.
        guard let scheme = request.url.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return }
        switch ArticleAccess.decide(url: request.url, isPremium: request.isPremium, entitlement: accountModel.entitlement) {
        case .open(let url): presented = .article(url)
        case .paywall(let url): presented = .paywall(url)
        }
    }
}

/// Hovering, capsule-shaped tab bar.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    static let reservedHeight: CGFloat = 88

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in item(tab) }
        }
        .padding(6)
        .background(NewsTheme.tabBar, in: Capsule())
        .overlay(Capsule().stroke(NewsTheme.tabBarBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .padding(.horizontal, 28)
        .padding(.bottom, 6)
        // Like the system tab bar: labels grow with Dynamic Type, but not so far that the bar breaks.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func item(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button { selection = tab } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon).font(.system(size: 19, weight: .semibold))
                Text(tab.title).font(.caption2.weight(.semibold)).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : NewsTheme.textSecondary)
            .background(isSelected ? NewsTheme.breakingRed : Color.clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("tab-\(tab.rawValue)")
        // Labels stop growing at xxLarge (above), so — like the system tab bar — a long press shows the item
        // enlarged in the Large Content Viewer. Without it, Apple's accessibility audit flags the capped text.
        .accessibilityShowsLargeContentViewer {
            Image(systemName: tab.icon)
            Text(tab.title)
        }
    }
}

enum Presented: Identifiable {
    case article(URL)
    case paywall(URL)

    var id: String {
        switch self {
        case .article(let url): "article-\(url.absoluteString)"
        case .paywall(let url): "paywall-\(url.absoluteString)"
        }
    }
}

/// The publisher's article in an in-app browser (SFSafariViewController): we link out, we never copy content.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
