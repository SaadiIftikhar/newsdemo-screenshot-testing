import Foundation
import Games
import NewsCore
import NewsFixtures
import NewsUI
import XCTest

// Edge cases of a news app whose content changes every minute. Each class has an Android twin in
// FeatureLogicTests.kt that asserts the SAME literals, so the platforms cannot drift apart.

/// Messy editorial text, as CMS/RSS sources really deliver it (fixtures/feed/feed_hostile_content.json).
final class HostileContentContractTests: XCTestCase {
    func test_hostileContent_isCleanedTheSameWayAsOnAndroid() throws {
        let feed = try FixtureStore.repository().feed("feed_hostile_content")
        XCTAssertEqual(feed.breaking?.headline,
                       "Bundestag stimmt über „Sondervermögen“ ab & Opposition kündigt Klage an")
        // "brk-301" is also used by a teaser: an item may never reuse the banner's id.
        XCTAssertEqual(feed.items.map(\.id), ["live-301", "tsr-301", "tsr-302", "vid-301", "tsr-303"])

        guard case .liveTicker(let ticker) = feed.items[0], case .teaser(let hyphenated) = feed.items[1],
              case .teaser(let entities) = feed.items[2], case .video(let video) = feed.items[3],
              case .teaser(let lines) = feed.items[4] else { return XCTFail("unexpected item types") }
        XCTAssertNil(ticker.latestUpdate, "a ticker before its first entry still shows (it used to be dropped)")
        XCTAssertEqual(ticker.kicker, "")
        XCTAssertEqual(hyphenated.kicker, "", "a whitespace-only kicker is cleaned to empty and not rendered")
        XCTAssertEqual(hyphenated.headline,
                       "Bundes\u{AD}verfassungs\u{AD}gerichts\u{AD}entscheidung zur Grund\u{AD}steuer\u{AD}reform",
                       "soft hyphens from the CMS are kept: they are what lets long German words break")
        XCTAssertEqual(entities.kicker, "KULTUR & MEDIEN")
        XCTAssertEqual(entities.headline, "\"Tatort\"-Kritik: „Zu laut, zu lang“ – Müller & Söhne 🎬")
        XCTAssertNil(entities.summary, "a whitespace-only summary must not leave an empty line")
        XCTAssertEqual(video.durationSeconds, 3723)
        XCTAssertEqual(lines.summary, "Zeile eins Zeile zwei mit Tab")
    }

    func test_textCleanerRules() {
        XCTAssertEqual(TextCleaner.clean("Müller & Söhne"), "Müller & Söhne", "a lone & is text")
        XCTAssertEqual(TextCleaner.clean("A &unknown; B"), "A &unknown; B", "unknown entities stay visible for review")
        XCTAssertEqual(TextCleaner.clean("&#xZZ; &#99999999;"), "&#xZZ; &#99999999;", "invalid code points stay as written")
        XCTAssertEqual(TextCleaner.clean("10&nbsp;000 &euro;"), "10\u{A0}000 €", "a non-breaking space is intentional")
        XCTAssertEqual(TextCleaner.clean("Fußball&shy;bundesliga"), "Fußball\u{AD}bundesliga")
        XCTAssertEqual(TextCleaner.clean(" \n\t "), "")
        XCTAssertEqual(TextCleaner.clean("&amp;amp;"), "&amp;", "decoded once, never twice")
    }
}

/// Time is the most "continuously changing" input of all. Boundaries, daylight saving, New Year, clock skew.
final class TimeBoundaryTests: XCTestCase {
    let now = FixtureEnvironment.now // 2026-11-05T14:13:20Z = 15:13:20 in Berlin
    let berlin = FixtureEnvironment.timeZone

    private func relative(secondsAgo: TimeInterval) -> String {
        NewsDateFormatter.relative(now.addingTimeInterval(-secondsAgo), now: now, timeZone: berlin)
    }

    func test_relativeBoundaries() {
        XCTAssertEqual(relative(secondsAgo: 0), "gerade eben")
        XCTAssertEqual(relative(secondsAgo: 59), "gerade eben")
        XCTAssertEqual(relative(secondsAgo: 60), "vor 1 Min.")
        XCTAssertEqual(relative(secondsAgo: 3599), "vor 59 Min.")
        XCTAssertEqual(relative(secondsAgo: 3600), "vor 1 Std.")
        XCTAssertEqual(relative(secondsAgo: 24 * 3600 - 1), "vor 23 Std.")
        XCTAssertEqual(relative(secondsAgo: 24 * 3600), "04.11.2026, 15:13 Uhr")
    }

    func test_futureTimestamps_clockSkewOrCMSTimezoneBug_neverShowNegativeTime() {
        XCTAssertEqual(relative(secondsAgo: -100), "gerade eben")
        XCTAssertEqual(relative(secondsAgo: -2 * 3600), "gerade eben", "no 'vor -120 Min.'")
    }

    func test_daylightSavingEnd_bothHalvesOfTheRepeatedHourShowLocalTime() {
        // 25.10.2026: 03:00 CEST → 02:00 CET. 00:30Z and 01:30Z are both "02:30" on a Berlin wall clock.
        XCTAssertEqual(NewsDateFormatter.relative(Date(timeIntervalSince1970: 1_792_888_200), now: now, timeZone: berlin),
                       "25.10.2026, 02:30 Uhr")
        XCTAssertEqual(NewsDateFormatter.relative(Date(timeIntervalSince1970: 1_792_891_800), now: now, timeZone: berlin),
                       "25.10.2026, 02:30 Uhr")
        XCTAssertEqual(NewsDateFormatter.relative(Date(timeIntervalSince1970: 1_782_900_000), now: now, timeZone: berlin),
                       "01.07.2026, 12:00 Uhr", "summer time is UTC+2")
    }

    func test_newYear_crossesTheYearInLocalTime() {
        let lateUTC = Date(timeIntervalSince1970: 1_798_759_800) // 2026-12-31T23:30Z
        let later = Date(timeIntervalSince1970: 1_799_150_400)   // 2027-01-05
        XCTAssertEqual(NewsDateFormatter.relative(lateUTC, now: later, timeZone: berlin), "01.01.2027, 00:30 Uhr")
    }

    func test_videoDuration() {
        XCTAssertEqual(NewsDateFormatter.duration(0), "0:00")
        XCTAssertEqual(NewsDateFormatter.duration(59), "0:59")
        XCTAssertEqual(NewsDateFormatter.duration(3599), "59:59")
        XCTAssertEqual(NewsDateFormatter.duration(3600), "1:00:00")
        XCTAssertEqual(NewsDateFormatter.duration(3723), "1:02:03", "it used to show 62:03")
        XCTAssertEqual(NewsDateFormatter.duration(-5), "0:00")
    }

    func test_asOf_usesTheLocalDay() {
        XCTAssertEqual(NewsDateFormatter.asOf(Date(timeIntervalSince1970: 1_793_887_320), now: now, timeZone: berlin), "15:02 Uhr")
        XCTAssertEqual(NewsDateFormatter.asOf(Date(timeIntervalSince1970: 1_793_800_920), now: now, timeZone: berlin),
                       "04.11.2026, 15:02 Uhr")
        // 2026-11-04T23:30Z is already 5 November in Berlin: "today", although UTC still says the 4th.
        XCTAssertEqual(NewsDateFormatter.asOf(Date(timeIntervalSince1970: 1_793_835_000), now: now, timeZone: berlin), "00:30 Uhr")
    }
}

/// Content changes while the reader is offline: the last feed must stay on screen.
@MainActor
final class CachedContentTests: XCTestCase {
    func test_refreshFailure_keepsTheLoadedFeed_markedStale() async throws {
        let store = FixtureStore.repository()
        let loadedAt = FixtureEnvironment.now
        let model = FeedViewModel(client: .droppingConnection(after: store.client("feed_default")), now: { loadedAt })

        await model.load()
        guard case .loaded(let feed) = model.state else { return XCTFail("first load should succeed") }

        await model.load() // pull to refresh in a tunnel
        XCTAssertEqual(model.state, .stale(feed, since: loadedAt, reason: .offline))
    }

    func test_firstLoadFailure_withNothingCached_showsTheErrorScreen() async {
        let model = FeedViewModel(client: .failing(.offline))
        await model.load()
        XCTAssertEqual(model.state, .failed(.offline))
    }
}

/// Property-based decoding: corrupt ONE item in many seeded ways; every other item must still be shown.
/// Real feeds change shape without warning; this is the "one bad item never takes the front page down" rule.
final class FeedDecodingFuzzTests: XCTestCase {
    func test_oneCorruptedItem_neverTakesOtherItemsDown() throws {
        let url = FixtureStore.repository().root.appendingPathComponent("feed/feed_default.json")
        let original = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        let items = original["items"] as! [[String: Any]]
        let decoder = NewsDecoder.make()
        let baseline = try decoder.decode(Feed.self, from: Data(contentsOf: url)).items.map(\.id)
        var rng = SplitMix64(seed: 2026)
        let junk: [Any] = [NSNull(), 42, "", ["nested": true], [1, 2], true]

        for round in 0..<300 {
            var mutated = items
            let index = Int(rng.next() % UInt64(items.count))
            var item = mutated[index]
            let keys = item.keys.sorted()
            let key = keys[Int(rng.next() % UInt64(keys.count))]
            if rng.next() % 3 == 0 { item.removeValue(forKey: key) } else { item[key] = junk[Int(rng.next() % UInt64(junk.count))] }
            mutated[index] = item
            var json = original
            json["items"] = mutated
            let data = try JSONSerialization.data(withJSONObject: json)

            let feed: Feed
            do { feed = try decoder.decode(Feed.self, from: data) } catch {
                return XCTFail("round \(round): corrupting \(key) of item \(index) failed the WHOLE feed: \(error)")
            }
            let ids = feed.items.map(\.id)
            let corruptedId = items[index]["id"] as? String
            XCTAssertEqual(Set(ids).count, ids.count, "round \(round): duplicate ids")
            XCTAssertNotNil(feed.breaking, "round \(round): an item error must not drop the breaking banner")
            for id in baseline where id != corruptedId {
                XCTAssertTrue(ids.contains(id), "round \(round): corrupting \(key) of \(corruptedId ?? "?") dropped \(id)")
            }
        }
    }
}
