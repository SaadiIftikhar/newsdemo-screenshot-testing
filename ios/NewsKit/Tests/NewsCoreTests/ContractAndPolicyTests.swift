import Account
import NewsCore
import NewsFixtures
import NewsUI
import UIKit
import XCTest

/// Cross-platform contract for messy backend data. Android asserts the SAME expectations (same ids, same flags),
/// so the two decoders cannot drift apart again (they did: a missing `premium` failed the whole feed on iOS and
/// silently became "free" on Android).
final class EdgeCaseDecodingContractTests: XCTestCase {
    func test_edgeCases_decodeToTheSameItemsAsAndroid() throws {
        let feed = try FixtureStore.repository().feed("feed_edge_cases")
        XCTAssertNil(feed.breaking)
        XCTAssertEqual(feed.items.map(\.id), ["live-201", "tsr-201", "ad-201", "tsr-202", "tsr-203"])

        guard case .liveTicker(let ticker) = feed.items[0], case .teaser(let free) = feed.items[1],
              case .ad(let ad) = feed.items[2], case .teaser(let archive) = feed.items[3],
              case .teaser(let fractional) = feed.items[4] else { return XCTFail("unexpected item types") }
        XCTAssertFalse(ticker.isLive)
        XCTAssertFalse(free.isPremium, "missing `premium` means free, not a decoding error")
        XCTAssertEqual(free.kicker, "TESTFALL", "duplicate id: the first entry wins")
        XCTAssertFalse(ad.filled)
        XCTAssertEqual(ad.height, 250.5)
        XCTAssertTrue(archive.isPremium)
        XCTAssertEqual(fractional.publishedAt.timeIntervalSince1970, 1_793_884_460.5, accuracy: 0.001)
    }
}

/// What each golden MEANS. If someone edits a fixture so "the premium teaser" is no longer premium, a re-record
/// would approve a premium golden without a badge. These tests fail first.
final class FixturePreconditionTests: XCTestCase {
    func test_snapshotFixturesStillMeanWhatTheTestsAssume() throws {
        let store = FixtureStore.repository()
        let main = try store.feed("feed_default")
        let long = try store.feed("feed_long_headlines")
        func teaser(_ id: String, _ feed: Feed) throws -> Teaser {
            for case .teaser(let t) in feed.items where t.id == id { return t }
            return try XCTUnwrap(nil as Teaser?, "\(id) missing")
        }
        XCTAssertNotNil(main.breaking)
        XCTAssertTrue(try teaser("tsr-002", main).isPremium, "test_teaserCard_premium needs a PLUS teaser")
        XCTAssertTrue(try teaser("tsr-101", long).isPremium)
        XCTAssertNotNil(try teaser("tsr-001", main).image, "test_teaserCard_withImage needs an image")
        XCTAssertNil(try teaser("tsr-003", main).image, "test_teaserCard_withoutImage needs no image")
        XCTAssertTrue(main.items.contains { $0.id == "live-001" } && main.items.contains { $0.id == "vid-001" }
                      && main.items.contains { $0.id == "ad-001" })
    }
}

final class PaywallPolicyTests: XCTestCase {
    let url = URL(string: "https://www.welt.de/plus")!

    func test_freeArticlesAlwaysOpen() {
        for entitlement in [Entitlement.anonymous, .registered, .subscriber] {
            XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: false, entitlement: entitlement), .open(url))
        }
    }

    func test_plusArticlesOpenOnlyForSubscribers() {
        XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: true, entitlement: .anonymous), .paywall(url))
        XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: true, entitlement: .registered), .paywall(url))
        XCTAssertEqual(ArticleAccess.decide(url: url, isPremium: true, entitlement: .subscriber), .open(url))
    }

    @MainActor
    func test_entitlementFollowsTheAccount() async {
        let model = AccountViewModel(client: .demo, email: AuthClient.basicEmail, password: AuthClient.demoPassword)
        XCTAssertEqual(model.entitlement, .anonymous)
        await model.signIn()
        XCTAssertEqual(model.entitlement, .registered)
        let plus = AccountViewModel(client: .demo, email: AuthClient.demoEmail, password: AuthClient.demoPassword)
        await plus.signIn()
        XCTAssertEqual(plus.entitlement, .subscriber)
    }
}

/// Every branch of the timestamp formatter, including a hostile device locale (the "11:05 PM Uhr" bug).
final class DateFormatterTests: XCTestCase {
    let now = FixtureEnvironment.now
    let berlin = FixtureEnvironment.timeZone

    func test_relativeBranches() {
        XCTAssertEqual(NewsDateFormatter.relative(now.addingTimeInterval(-20), now: now, timeZone: berlin), "gerade eben")
        XCTAssertEqual(NewsDateFormatter.relative(now.addingTimeInterval(-9 * 60), now: now, timeZone: berlin), "vor 9 Min.")
        XCTAssertEqual(NewsDateFormatter.relative(now.addingTimeInterval(-5 * 3600), now: now, timeZone: berlin), "vor 5 Std.")
    }

    func test_olderThanADay_isGerman24h_evenWithAnEnglishDeviceLocale() {
        let date = Date(timeIntervalSince1970: 1_793_607_600) // 2026-11-02T08:20:00Z = 09:20 Berlin
        let text = NewsDateFormatter.relative(date, now: now, locale: Locale(identifier: "en_US"), timeZone: berlin)
        XCTAssertEqual(text, "02.11.2026, 09:20 Uhr")
        XCTAssertFalse(text.contains("AM") || text.contains("PM"))
    }
}

/// WCAG 2.2 contrast of every text-on-background token pair, light and dark. Golden review missed contrast bugs
/// (the screenshots were approved); this test would have caught them. Android runs the same pairs.
final class ContrastTests: XCTestCase {
    struct Pair { let name: String; let fg: UIColor; let bg: UIColor; let minimum: Double }

    let pairs: [Pair] = [
        Pair(name: "primary text on background", fg: NewsPalette.textPrimary, bg: NewsPalette.background, minimum: 4.5),
        Pair(name: "primary text on card", fg: NewsPalette.textPrimary, bg: NewsPalette.card, minimum: 4.5),
        Pair(name: "secondary text on background", fg: NewsPalette.textSecondary, bg: NewsPalette.background, minimum: 4.5),
        Pair(name: "secondary text on card", fg: NewsPalette.textSecondary, bg: NewsPalette.card, minimum: 4.5),
        Pair(name: "tab label on tab bar", fg: NewsPalette.textSecondary, bg: NewsPalette.tabBar, minimum: 4.5),
        Pair(name: "kicker on card", fg: NewsPalette.kicker, bg: NewsPalette.card, minimum: 4.5),
        Pair(name: "accent text on background", fg: NewsPalette.accentText, bg: NewsPalette.background, minimum: 4.5),
        Pair(name: "accent text on card", fg: NewsPalette.accentText, bg: NewsPalette.card, minimum: 4.5),
        Pair(name: "white on brand red (banner, buttons)", fg: .white, bg: NewsPalette.breakingRed, minimum: 4.5),
        Pair(name: "black on PLUS gold", fg: .black, bg: NewsPalette.premiumGold, minimum: 4.5),
        Pair(name: "live dot on card (non-text)", fg: NewsPalette.liveRed, bg: NewsPalette.card, minimum: 3.0),
    ]

    func test_allTokenPairsMeetWCAG_inLightAndDark() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for pair in pairs {
                let ratio = Self.contrast(pair.fg, on: pair.bg, traits: traits)
                XCTAssertGreaterThanOrEqual(ratio, pair.minimum,
                    "\(pair.name) (\(style == .dark ? "dark" : "light")): \(String(format: "%.2f", ratio)):1")
            }
        }
    }

    // MARK: WCAG maths

    static func contrast(_ fg: UIColor, on bg: UIColor, traits: UITraitCollection) -> Double {
        let base = rgba(NewsPalette.background.resolvedColor(with: traits))
        let background = over(rgba(bg.resolvedColor(with: traits)), base)
        let foreground = over(rgba(fg.resolvedColor(with: traits)), background)
        let (l1, l2) = (luminance(foreground), luminance(background))
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    typealias RGBA = (r: Double, g: Double, b: Double, a: Double)

    static func rgba(_ color: UIColor) -> RGBA {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }

    /// Alpha-composite `top` over an opaque `bottom`.
    static func over(_ top: RGBA, _ bottom: RGBA) -> RGBA {
        (top.r * top.a + bottom.r * (1 - top.a), top.g * top.a + bottom.g * (1 - top.a),
         top.b * top.a + bottom.b * (1 - top.a), 1)
    }

    static func luminance(_ c: RGBA) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }
}
