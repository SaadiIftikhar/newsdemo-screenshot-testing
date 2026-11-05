import NewsCore
import Observation
import SwiftUI

public enum FeedState: Equatable, Sendable {
    case loading
    case loaded(Feed)
    case empty
    case failed(FeedError)
}

@MainActor
@Observable
public final class FeedViewModel {
    public private(set) var state: FeedState = .loading
    private let client: FeedClient

    public init(client: FeedClient) { self.client = client }

    public func load() async {
        state = .loading
        do {
            let feed = try await client.fetchFeed()
            state = feed.isEmpty ? .empty : .loaded(feed)
        } catch let error as FeedError {
            state = .failed(error)
        } catch {
            state = .failed(.server(status: -1))
        }
    }
}

/// The screen as shipped: owns a view model, loads on appear.
public struct FeedScreen: View {
    @State private var viewModel: FeedViewModel

    public init(viewModel: FeedViewModel) { _viewModel = State(initialValue: viewModel) }

    public var body: some View {
        FeedView(state: viewModel.state, onRetry: { Task { await viewModel.load() } })
            .task { if viewModel.state == .loading { await viewModel.load() } }
    }
}

/// Pure rendering of a FeedState. Snapshot tests target this directly for every state.
public struct FeedView: View {
    let state: FeedState
    var onRetry: () -> Void

    public init(state: FeedState, onRetry: @escaping () -> Void = {}) {
        self.state = state
        self.onRetry = onRetry
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
            Spacer()
            Image(systemName: "person.crop.circle").font(.title2).foregroundStyle(NewsTheme.textSecondary)
        }
        .padding(.horizontal, NewsTheme.spacing)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView().padding(.top, 80)
        case .empty:
            StatusMessage(icon: "newspaper", title: "Noch keine Artikel", message: "Schauen Sie später wieder vorbei.")
        case .failed(.offline):
            StatusMessage(icon: "wifi.slash", title: "Keine Internetverbindung",
                          message: "Bitte prüfen Sie Ihre Verbindung.", actionTitle: "Erneut versuchen", action: onRetry)
        case .failed:
            StatusMessage(icon: "exclamationmark.triangle", title: "Etwas ist schiefgelaufen",
                          message: "Der Feed konnte nicht geladen werden.", actionTitle: "Erneut versuchen", action: onRetry)
        case .loaded(let feed):
            ScrollView {
                LazyVStack(spacing: NewsTheme.spacing) {
                    if let breaking = feed.breaking {
                        BreakingNewsBanner(news: breaking)
                    }
                    ForEach(feed.items) { item in
                        FeedItemView(item: item).padding(.horizontal, NewsTheme.spacing)
                    }
                }
                .padding(.bottom, NewsTheme.spacing)
            }
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

struct StatusMessage: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(NewsTheme.textSecondary)
            Text(title).font(.title3.weight(.bold)).foregroundStyle(NewsTheme.textPrimary)
            Text(message).font(.body).foregroundStyle(NewsTheme.textSecondary).multilineTextAlignment(.center)
            if let actionTitle {
                Button(actionTitle, action: action).buttonStyle(.borderedProminent).tint(NewsTheme.breakingRed)
            }
        }
        .padding(32)
        .padding(.top, 60)
    }
}
