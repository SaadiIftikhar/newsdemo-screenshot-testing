import NewsCore
import SwiftUI

// MARK: - Shared building blocks

struct Timestamp: View {
    let date: Date
    /// Explicit colour: an outer `.foregroundStyle` does not override an inner one, which made the
    /// banner timestamp grey-on-red in light mode (caught while reviewing the first goldens).
    var color: Color = NewsTheme.textSecondary
    /// Publisher credit ("WELT · vor 9 Min.") — required when we link out to someone else's article.
    var source: String? = nil
    /// Shows ↗ so readers know the item opens the publisher's page.
    var isLink: Bool = false
    @Environment(\.now) private var now
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        let relative = NewsDateFormatter.relative(date, now: now, timeZone: timeZone)
        HStack(spacing: 3) {
            Text(source.map { "\($0) · \(relative)" } ?? relative)
            if isLink { Image(systemName: "arrow.up.right").imageScale(.small).accessibilityHidden(true) }
        }
        .font(.caption)
        .foregroundStyle(color)
    }
}

/// Image view behind the ImageProvider seam: async in production, synchronous in tests.
public struct RemoteImage: View {
    let name: String
    @Environment(\.imageProvider) private var provider

    public init(name: String) { self.name = name }

    public var body: some View {
        switch provider {
        case .remote(let baseURL):
            AsyncImage(url: baseURL.appendingPathComponent(name)) { phase in
                if let image = phase.image { image.resizable().scaledToFill() } else { ImagePlaceholder() }
            }
        case .local(let load):
            if let image = load(name) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ImagePlaceholder()
            }
        }
    }
}

/// Shown while an image loads or when it fails: a neutral photo glyph, so a failed image does not look broken
/// (a bare grey box under a play button looked like a bug). Decorative, hidden from VoiceOver.
struct ImagePlaceholder: View {
    var body: some View {
        ZStack {
            NewsTheme.card
            Image(systemName: "photo").font(.system(size: 34)).foregroundStyle(NewsTheme.textSecondary)
        }
        .accessibilityHidden(true)
    }
}

struct PremiumBadge: View {
    var body: some View {
        Label("PLUS", systemImage: "star.fill")
            .font(.caption2.weight(.heavy))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(NewsTheme.premiumGold, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(.black)
            .accessibilityLabel("Plus-Artikel")
    }
}

struct Kicker: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(NewsTheme.kicker)
    }
}

// MARK: - Breaking news banner

public struct BreakingNewsBanner: View {
    let news: BreakingNews
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(news: BreakingNews) { self.news = news }

    /// At accessibility sizes the timestamp moves to its own line; sharing the row it forced
    /// the label to hyphenate as "EILMEL-DUNG" (caught by the light_xxxl snapshot).
    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 6))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerLayout {
                Label("EILMELDUNG", systemImage: "bolt.fill")
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                    .fixedSize()
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                // Full white: 85% white on the red was only ≈4.3:1 (accessibility review).
                Timestamp(date: news.publishedAt, color: .white, source: news.source, isLink: news.url != nil)
            }
            Text(news.headline)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
        .padding(NewsTheme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NewsTheme.breakingRed)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Live ticker

public struct LiveTickerCard: View {
    let ticker: LiveTicker
    @Environment(\.animationsEnabled) private var animationsEnabled
    @State private var pulse = false

    public init(ticker: LiveTicker) { self.ticker = ticker }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(ticker.isLive ? NewsTheme.liveRed : NewsTheme.textSecondary)
                    .frame(width: 8, height: 8)
                    .opacity(pulse ? 0.3 : 1)
                    .accessibilityHidden(true)
                // Text uses accentText: liveRed as small text is only ≈4.3:1 on the light card.
                Text(ticker.isLive ? ticker.kicker : "BEENDET")
                    .font(.caption.weight(.black))
                    .foregroundStyle(ticker.isLive ? NewsTheme.accentText : NewsTheme.textSecondary)
                Spacer(minLength: 0)
                Timestamp(date: ticker.updatedAt, source: ticker.source, isLink: ticker.url != nil)
            }
            Text(ticker.headline).font(.headline).foregroundStyle(NewsTheme.textPrimary)
            Text(ticker.latestUpdate).font(.subheadline).foregroundStyle(NewsTheme.textSecondary)
        }
        .padding(NewsTheme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
        .onAppear {
            guard animationsEnabled, ticker.isLive else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) { pulse = true }
        }
        // Reset when the cell scrolls away, so the pulse restarts when it comes back (lazy stacks reuse state).
        .onDisappear { pulse = false }
    }
}

// MARK: - Teaser card (with / without image, optional premium)

public struct TeaserCard: View {
    let teaser: Teaser
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(teaser: Teaser) { self.teaser = teaser }

    /// At accessibility text sizes badge + kicker stack vertically; side by side the kicker was
    /// truncated to "GESELLSC…" (caught by the light_xxxl snapshot).
    private var badgeLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 6))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image = teaser.image {
                RemoteImage(name: image)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipped()
            }
            VStack(alignment: .leading, spacing: 6) {
                badgeLayout {
                    if teaser.isPremium { PremiumBadge() }
                    Kicker(text: teaser.kicker)
                }
                Text(teaser.headline)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(NewsTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let summary = teaser.summary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(NewsTheme.textSecondary)
                        .lineLimit(3)
                }
                Timestamp(date: teaser.publishedAt, source: teaser.source, isLink: teaser.url != nil)
            }
            .padding(NewsTheme.spacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NewsTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
    }
}

// MARK: - Video teaser

public struct VideoTeaserCard: View {
    let video: VideoTeaser

    public init(video: VideoTeaser) { self.video = video }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(name: video.image)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipped()
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white, .black.opacity(0.45))
                    }
                Text(NewsDateFormatter.duration(video.durationSeconds))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(.white)
                    .padding(8)
            }
            VStack(alignment: .leading, spacing: 6) {
                Kicker(text: video.kicker)
                Text(video.headline).font(.headline).foregroundStyle(NewsTheme.textPrimary)
                Timestamp(date: video.publishedAt, source: video.source, isLink: video.url != nil)
            }
            .padding(NewsTheme.spacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NewsTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
    }
}

// MARK: - Ad slot (the real ad SDK is replaced by a fixed-size placeholder in tests and in the demo)

public struct AdSlotView: View {
    let slot: AdSlot

    public init(slot: AdSlot) { self.slot = slot }

    public var body: some View {
        // No fill → collapse completely instead of reserving an empty grey box.
        if slot.filled { filledBody }
    }

    private var filledBody: some View {
        VStack(spacing: 4) {
            // "Anzeige" is legally required next to every ad (separation of ads and editorial content).
            Text("Anzeige").font(.caption2).foregroundStyle(NewsTheme.textSecondary)
            RoundedRectangle(cornerRadius: 6)
                .fill(NewsTheme.adBackground)
                .frame(height: slot.height)
                .overlay(Text(slot.slot).font(.caption.monospaced()).foregroundStyle(NewsTheme.textSecondary))
        }
    }
}
