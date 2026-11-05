import NewsCore
import SwiftUI

// MARK: - Shared building blocks

struct Timestamp: View {
    let date: Date
    /// Explicit colour: an outer `.foregroundStyle` does not override an inner one, which made the
    /// banner timestamp grey-on-red in light mode (caught while reviewing the first goldens).
    var color: Color = NewsTheme.textSecondary
    @Environment(\.now) private var now
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    var body: some View {
        Text(NewsDateFormatter.relative(date, now: now, locale: locale, timeZone: timeZone))
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
            AsyncImage(url: baseURL.appendingPathComponent(name)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                NewsTheme.card
            }
        case .local(let load):
            if let image = load(name) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                NewsTheme.card
            }
        }
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
                Timestamp(date: news.publishedAt, color: .white.opacity(0.85))
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
                    .fill(NewsTheme.liveRed)
                    .frame(width: 8, height: 8)
                    .opacity(pulse ? 0.3 : 1)
                Text(ticker.kicker).font(.caption.weight(.black)).foregroundStyle(NewsTheme.liveRed)
                Spacer(minLength: 0)
                Timestamp(date: ticker.updatedAt)
            }
            Text(ticker.headline).font(.headline).foregroundStyle(NewsTheme.textPrimary)
            Text(ticker.latestUpdate).font(.subheadline).foregroundStyle(NewsTheme.textSecondary)
        }
        .padding(NewsTheme.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
        .onAppear {
            guard animationsEnabled else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) { pulse = true }
        }
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
                Timestamp(date: teaser.publishedAt)
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
                Timestamp(date: video.publishedAt)
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
        VStack(spacing: 4) {
            Text("Anzeige").font(.caption2).foregroundStyle(NewsTheme.textSecondary)
            RoundedRectangle(cornerRadius: 6)
                .fill(NewsTheme.adBackground)
                .frame(height: slot.height)
                .overlay(Text(slot.slot).font(.caption.monospaced()).foregroundStyle(NewsTheme.textSecondary))
        }
    }
}
