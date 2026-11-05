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
/// Why not the system `TabView`? On iOS 26 its floating "Liquid Glass" bar is not captured by in-process
/// snapshots (the glass renders blank, and lazy tab content isn't laid out before capture), so it could not be
/// regression-tested. A custom bar is fully snapshot-testable and looks identical on Android. The cost:
/// accessibility (selected trait, labels, capped text size) is implemented by hand below.
public struct RootView: View {
    @State private var selection: AppTab
    private let feedViewModel: FeedViewModel
    private let accountModel: AccountViewModel
    private let gamesPath: [GameKind]
    @State private var openedArticle: OpenedArticle?

    public init(feedViewModel: FeedViewModel, accountModel: AccountViewModel,
                initialTab: AppTab = .feed, gamesPath: [GameKind] = []) {
        self.feedViewModel = feedViewModel
        self.accountModel = accountModel
        self.gamesPath = gamesPath
        _selection = State(initialValue: initialTab)
    }

    public var body: some View {
        ZStack {
            // All tabs stay alive (like a system tab bar), so each keeps its state when you switch.
            tab(.feed) { FeedScreen(viewModel: feedViewModel, onOpenArticle: { openedArticle = OpenedArticle(url: $0) }) }
            tab(.games) { GamesHome(path: gamesPath) }
            tab(.account) { AccountScreen(model: accountModel) }
        }
        // Scrollable content can scroll *under* the floating bar but always ends above it.
        .contentMargins(.bottom, FloatingTabBar.reservedHeight, for: .scrollContent)
        .overlay(alignment: .bottom) { FloatingTabBar(selection: $selection) }
        .sheet(item: $openedArticle) { article in
            SafariView(url: article.url).ignoresSafeArea()
        }
    }

    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder _ content: () -> Content) -> some View {
        let isSelected = selection == tab
        return content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
    }
}

/// Hovering, capsule-shaped tab bar (mirrored by the Compose `FloatingTabBar` on Android).
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
    }
}

struct OpenedArticle: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// The publisher's article in an in-app browser (SFSafariViewController): we link out, we never copy content.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
