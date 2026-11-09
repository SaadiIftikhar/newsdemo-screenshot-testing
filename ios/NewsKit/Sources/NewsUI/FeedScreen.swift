import NewsCore
import Observation
import SwiftUI

public enum FeedState: Equatable, Sendable {
    case loading
    case loaded(Feed)
    case empty
    case failed(FeedError)
    /// A refresh failed but earlier content exists: keep showing it, with a notice and the time it was loaded.
    /// (Wiping a full feed off the screen because a train went into a tunnel is the worst offline behaviour.)
    case stale(Feed, since: Date, reason: FeedError)

    /// The feed currently on screen, if any.
    public var feed: Feed? {
        switch self {
        case .loaded(let feed), .stale(let feed, _, _): feed
        default: nil
        }
    }
}

/// A tap on an article. The app shell decides (ArticleAccess) whether it opens or shows the paywall.
public struct ArticleRequest: Equatable, Sendable {
    public let url: URL
    public let isPremium: Bool

    public init(url: URL, isPremium: Bool) {
        self.url = url
        self.isPremium = isPremium
    }
}

@MainActor
@Observable
public final class FeedViewModel {
    public private(set) var state: FeedState = .loading
    private let client: FeedClient
    private let now: @Sendable () -> Date
    private var loadTask: Task<Void, Never>?
    private var loadedAt: Date?

    public init(client: FeedClient, now: @escaping @Sendable () -> Date = { Date() }) {
        self.client = client
        self.now = now
    }

    /// First load and pull-to-refresh. Content already on screen stays there while refreshing, and stays
    /// there (marked stale) if the refresh fails.
    public func load() async {
        let shown = state.feed
        if shown == nil { state = .loading }
        do {
            let feed = try await client.fetchFeed()
            state = feed.isEmpty ? .empty : .loaded(feed)
            loadedAt = now()
        } catch is CancellationError {
            return // superseded by a newer load: not an error the user should see
        } catch {
            let reason = (error as? FeedError) ?? .server(status: -1)
            if let shown, let loadedAt {
                state = .stale(shown, since: loadedAt, reason: reason)
            } else {
                state = .failed(reason)
            }
        }
    }

    /// Retry/refresh: cancels a load still in flight, so the last request — not the slowest — wins.
    public func reload() {
        loadTask?.cancel()
        loadTask = Task { await load() }
    }
}

/// The screen as shipped: loads on first appearance.
public struct FeedScreen: View {
    private let viewModel: FeedViewModel // owned by the app shell; @Observable tracks reads in `body`
    private let onOpenArticle: (ArticleRequest) -> Void

    public init(viewModel: FeedViewModel, onOpenArticle: @escaping (ArticleRequest) -> Void = { _ in }) {
        self.viewModel = viewModel
        self.onOpenArticle = onOpenArticle
    }

    public var body: some View {
        FeedView(state: viewModel.state, onRetry: viewModel.reload, onRefresh: { await viewModel.load() },
                 onOpenArticle: onOpenArticle)
            .task { if viewModel.state == .loading { await viewModel.load() } }
    }
}

/// Pure rendering of a FeedState. Snapshot tests target this directly for every state.
public struct FeedView: View {
    let state: FeedState
    var onRetry: () -> Void
    var onRefresh: () async -> Void
    var onOpenArticle: (ArticleRequest) -> Void

    /// Feed column width cap: on tablets the cards stay readable instead of stretching edge to edge.
    static let maxContentWidth: CGFloat = 640

    public init(state: FeedState, onRetry: @escaping () -> Void = {}, onRefresh: @escaping () async -> Void = {},
                onOpenArticle: @escaping (ArticleRequest) -> Void = { _ in }) {
        self.state = state
        self.onRetry = onRetry
        self.onRefresh = onRefresh
        self.onOpenArticle = onOpenArticle
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(NewsTheme.background)
    }

    private var header: some View {
        HStack {
            Text("NewsDemo").font(.title2.weight(.black)).foregroundStyle(NewsTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Image(systemName: "person.crop.circle").font(.title2).foregroundStyle(NewsTheme.textSecondary)
                .accessibilityHidden(true) // decorative; the account lives in the Konto tab
        }
        .padding(.horizontal, NewsTheme.spacing)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            FeedSkeleton()
        case .empty:
            StatusMessage(icon: "newspaper", title: "Noch keine Artikel", message: "Schauen Sie später wieder vorbei.")
        case .failed(.offline):
            StatusMessage(icon: "wifi.slash", title: "Keine Internetverbindung",
                          message: "Bitte prüfen Sie Ihre Verbindung.", actionTitle: "Erneut versuchen", action: onRetry)
        case .failed:
            StatusMessage(icon: "exclamationmark.triangle", title: "Etwas ist schiefgelaufen",
                          message: "Der Feed konnte nicht geladen werden.", actionTitle: "Erneut versuchen", action: onRetry)
        case .loaded(let feed):
            list(feed, notice: nil)
        case .stale(let feed, let since, let reason):
            list(feed, notice: StaleNotice(since: since, reason: reason))
        }
    }

    private func list(_ feed: Feed, notice: StaleNotice?) -> some View {
            ScrollView {
                LazyVStack(spacing: NewsTheme.spacing) {
                    if let notice { notice.padding(.horizontal, NewsTheme.spacing) }
                    if let breaking = feed.breaking {
                        ArticleLink(request: breaking.url.map { ArticleRequest(url: $0, isPremium: false) }, open: onOpenArticle) {
                            BreakingNewsBanner(news: breaking)
                        }
                    }
                    ForEach(feed.items.filter(\.isVisible)) { item in
                        ArticleLink(request: item.articleURL.map { ArticleRequest(url: $0, isPremium: item.isPremium) },
                                    open: onOpenArticle) { FeedItemView(item: item) }
                            .accessibilityIdentifier("article-\(item.id)")
                            .padding(.horizontal, NewsTheme.spacing)
                    }
                }
                .padding(.bottom, NewsTheme.spacing)
                .frame(maxWidth: Self.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await onRefresh() } // pull to refresh
    }
}

extension FeedItem {
    /// Unfilled ads and unsupported items take no space at all.
    var isVisible: Bool {
        switch self {
        case .ad(let slot): slot.filled
        case .unsupported: false
        default: true
        }
    }
}

/// Makes a feed card tappable when it has a public article URL; otherwise renders it unchanged.
struct ArticleLink<Content: View>: View {
    let request: ArticleRequest?
    let open: (ArticleRequest) -> Void
    @ViewBuilder let content: Content

    var body: some View {
        if let request {
            Button { open(request) } label: { content }
                .buttonStyle(.plain)
                .accessibilityHint(request.isPremium ? "PLUS-Artikel" : "Öffnet den Artikel beim Herausgeber")
        } else {
            content
        }
    }
}

struct FeedItemView: View {
    let item: FeedItem

    var body: some View {
        switch item {
        case .teaser(let teaser): TeaserCard(teaser: teaser)
        case .liveTicker(let ticker): LiveTickerCard(ticker: ticker)
        case .video(let video): VideoTeaserCard(video: video)
        case .ad(let slot): AdSlotView(slot: slot)
        case .unsupported: EmptyView()
        }
    }
}

/// Static placeholder cards while the feed loads: deterministic (no spinner frame to race) and what users
/// of a news app expect on a cold start.
struct FeedSkeleton: View {
    var body: some View {
        VStack(spacing: NewsTheme.spacing) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 6).fill(NewsTheme.adBackground).aspectRatio(16 / 9, contentMode: .fit)
                    RoundedRectangle(cornerRadius: 4).fill(NewsTheme.adBackground).frame(width: 90, height: 12)
                    RoundedRectangle(cornerRadius: 4).fill(NewsTheme.adBackground).frame(height: 18)
                    RoundedRectangle(cornerRadius: 4).fill(NewsTheme.adBackground).frame(width: 220, height: 18)
                }
                .padding(NewsTheme.spacing)
                .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
            }
        }
        .padding(.horizontal, NewsTheme.spacing)
        .frame(maxWidth: FeedView.maxContentWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Artikel werden geladen")
    }
}

struct StatusMessage: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(NewsTheme.textSecondary)
                .accessibilityHidden(true)
            Text(title).font(.title3.weight(.bold)).foregroundStyle(NewsTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(message).font(.body).foregroundStyle(NewsTheme.textSecondary).multilineTextAlignment(.center)
            if let actionTitle {
                Button(actionTitle, action: action).buttonStyle(.borderedProminent).tint(NewsTheme.breakingRed)
            }
        }
        .padding(32)
        .padding(.top, 60)
    }
}
