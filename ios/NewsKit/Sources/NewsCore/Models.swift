import Foundation

// Decoding rules (enforced by the `feed_edge_cases.json` contract test; any other client must follow the same):
//  - one malformed item is DROPPED, never fails the whole feed (losing the front page during breaking news
//    is the most expensive failure a news app can have)
//  - unknown or missing `type` → dropped (forward compatibility)
//  - optional flags default sensibly: `premium` → false, `isLive` → true, ad `filled` → true
//  - duplicate ids → first one wins
//  - ISO-8601 dates with or without fractional seconds
//  - editorial text is cleaned (TextCleaner): HTML entities decoded, stray whitespace/line breaks collapsed,
//    soft hyphens kept. CMS and RSS content arrives like this every day; it must never reach the screen raw.

public struct Feed: Equatable, Sendable, Decodable {
    public var breaking: BreakingNews?
    public var items: [FeedItem]

    public init(breaking: BreakingNews? = nil, items: [FeedItem]) {
        self.breaking = breaking
        self.items = items
    }

    public var isEmpty: Bool { breaking == nil && items.isEmpty }

    enum CodingKeys: String, CodingKey { case breaking, items }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        breaking = (try? container.decodeIfPresent(BreakingNews.self, forKey: .breaking))?.cleaned
        let decoded = try container.decode([LossyItem].self, forKey: .items).compactMap(\.item)
        var seen = Set<String>()
        if let breaking { seen.insert(breaking.id) } // an item may not reuse the banner's id
        items = decoded.filter { $0 != .unsupported && seen.insert($0.id).inserted }.map(\.cleaned)
    }

    /// Decodes one item without letting its failure escape.
    private struct LossyItem: Decodable {
        let item: FeedItem?
        init(from decoder: any Decoder) throws { item = try? FeedItem(from: decoder) }
    }
}

public struct BreakingNews: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var headline: String
    public var publishedAt: Date
    /// Public article this item links out to (opened in the in-app browser). Nil = not tappable.
    public var url: URL?
    /// Publisher credit shown next to the timestamp, e.g. "WELT".
    public var source: String?
}

public enum FeedItem: Equatable, Sendable, Decodable, Identifiable {
    case teaser(Teaser)
    case liveTicker(LiveTicker)
    case video(VideoTeaser)
    case ad(AdSlot)
    case unsupported

    public var id: String {
        switch self {
        case .teaser(let t): t.id
        case .liveTicker(let l): l.id
        case .video(let v): v.id
        case .ad(let a): a.id
        case .unsupported: "unsupported"
        }
    }

    /// The public article this item opens, if any.
    public var articleURL: URL? {
        switch self {
        case .teaser(let t): t.url
        case .liveTicker(let l): l.url
        case .video(let v): v.url
        case .ad, .unsupported: nil
        }
    }

    /// Paywalled (PLUS) content.
    public var isPremium: Bool {
        if case .teaser(let t) = self { return t.isPremium }
        return false
    }

    enum TypeKey: String, CodingKey { case type }

    public init(from decoder: any Decoder) throws {
        let type = try decoder.container(keyedBy: TypeKey.self).decodeIfPresent(String.self, forKey: .type)
        switch type {
        case "teaser": self = .teaser(try Teaser(from: decoder))
        case "liveTicker": self = .liveTicker(try LiveTicker(from: decoder))
        case "video": self = .video(try VideoTeaser(from: decoder))
        case "ad": self = .ad(try AdSlot(from: decoder))
        default: self = .unsupported
        }
    }
}

public struct Teaser: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var kicker: String
    public var headline: String
    public var summary: String?
    public var image: String?
    public var publishedAt: Date
    public var isPremium: Bool
    public var url: URL?
    public var source: String?

    enum CodingKeys: String, CodingKey {
        case id, kicker, headline, summary, image, publishedAt, url, source
        case isPremium = "premium"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kicker = try c.decode(String.self, forKey: .kicker)
        headline = try c.decode(String.self, forKey: .headline)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        publishedAt = try c.decode(Date.self, forKey: .publishedAt)
        isPremium = try c.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false // missing → free, not a crash
        url = try c.decodeIfPresent(URL.self, forKey: .url)
        source = try c.decodeIfPresent(String.self, forKey: .source)
    }
}

public struct LiveTicker: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var kicker: String
    public var headline: String
    /// Nil before the first entry (e.g. a match ticker opened before kick-off): shown as "Noch keine Einträge".
    public var latestUpdate: String?
    public var updatedAt: Date
    /// False once the event is over: the ticker shows "BEENDET" and stops pulsing.
    public var isLive: Bool
    public var url: URL?
    public var source: String?

    enum CodingKeys: String, CodingKey { case id, kicker, headline, latestUpdate, updatedAt, isLive, url, source }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kicker = try c.decode(String.self, forKey: .kicker)
        headline = try c.decode(String.self, forKey: .headline)
        latestUpdate = try c.decodeIfPresent(String.self, forKey: .latestUpdate)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        isLive = try c.decodeIfPresent(Bool.self, forKey: .isLive) ?? true
        url = try c.decodeIfPresent(URL.self, forKey: .url)
        source = try c.decodeIfPresent(String.self, forKey: .source)
    }
}

public struct VideoTeaser: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var kicker: String
    public var headline: String
    public var image: String
    public var durationSeconds: Int
    public var publishedAt: Date
    public var url: URL?
    public var source: String?
}

public struct AdSlot: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var slot: String
    public var height: Double
    /// False when the ad network returned nothing ("no fill"): the slot collapses instead of showing a grey box.
    public var filled: Bool

    enum CodingKeys: String, CodingKey { case id, slot, height, filled }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        slot = try c.decode(String.self, forKey: .slot)
        height = try c.decode(Double.self, forKey: .height)
        filled = try c.decodeIfPresent(Bool.self, forKey: .filled) ?? true
    }
}

// MARK: - Text cleaning

/// Cleans editorial text from the CMS/feeds. The contract is
/// `fixtures/feed/feed_hostile_content.json`, asserted with the same literal on both platforms.
public enum TextCleaner {
    /// Entities that really occur in German editorial feeds. An unknown name stays as written (visible in review).
    private static let named: [String: String] = [
        "amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">", "nbsp": "\u{00A0}", "shy": "\u{00AD}",
        "ndash": "–", "mdash": "—", "hellip": "…", "euro": "€",
        "bdquo": "„", "ldquo": "“", "rdquo": "”", "sbquo": "‚", "lsquo": "‘", "rsquo": "’", "laquo": "«", "raquo": "»",
        "auml": "ä", "ouml": "ö", "uuml": "ü", "Auml": "Ä", "Ouml": "Ö", "Uuml": "Ü", "szlig": "ß",
    ]
    /// Only these collapse; a non-breaking space (U+00A0) and a soft hyphen (U+00AD) are intentional and stay.
    private static let collapsible: Set<Unicode.Scalar> = [" ", "\t", "\n", "\r"]

    public static func clean(_ text: String) -> String {
        var decoded = ""
        var rest = Substring(text)
        while let amp = rest.firstIndex(of: "&") {
            decoded += rest[..<amp]
            let after = rest[rest.index(after: amp)...]
            if let semi = after.prefix(10).firstIndex(of: ";"), let value = entity(after[..<semi]) {
                decoded += value
                rest = after[after.index(after: semi)...]
            } else {
                decoded += "&" // a lone "&" (e.g. "Müller & Söhne") is text, not an entity
                rest = after
            }
        }
        decoded += rest
        var result = "", pendingSpace = false
        for scalar in decoded.unicodeScalars {
            if collapsible.contains(scalar) { pendingSpace = !result.isEmpty; continue }
            if pendingSpace { result += " "; pendingSpace = false }
            result.unicodeScalars.append(scalar)
        }
        return result
    }

    private static func entity(_ body: Substring) -> String? {
        let scalar: Unicode.Scalar?
        if body.hasPrefix("#x") || body.hasPrefix("#X") {
            scalar = UInt32(body.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init)
        } else if body.hasPrefix("#") {
            scalar = UInt32(body.dropFirst()).flatMap(Unicode.Scalar.init)
        } else {
            return named[String(body)]
        }
        return scalar.map { String(Character($0)) }
    }

    /// Cleaned, or nil when nothing is left (an empty summary must not leave an empty line).
    static func cleanOptional(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleaned = clean(text)
        return cleaned.isEmpty ? nil : cleaned
    }
}

extension BreakingNews {
    var cleaned: BreakingNews { var copy = self; copy.headline = TextCleaner.clean(headline); return copy }
}

extension FeedItem {
    var cleaned: FeedItem {
        switch self {
        case .teaser(var t):
            t.kicker = TextCleaner.clean(t.kicker); t.headline = TextCleaner.clean(t.headline)
            t.summary = TextCleaner.cleanOptional(t.summary)
            return .teaser(t)
        case .liveTicker(var l):
            l.kicker = TextCleaner.clean(l.kicker); l.headline = TextCleaner.clean(l.headline)
            l.latestUpdate = TextCleaner.cleanOptional(l.latestUpdate)
            return .liveTicker(l)
        case .video(var v):
            v.kicker = TextCleaner.clean(v.kicker); v.headline = TextCleaner.clean(v.headline)
            return .video(v)
        case .ad, .unsupported:
            return self
        }
    }
}

public enum NewsDecoder {
    /// The single decoder used in production AND by fixtures — so fixtures also exercise real parsing.
    public static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            // Formatters are created per call: ISO8601DateFormatter is not Sendable.
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: text) ?? ISO8601DateFormatter().date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(text)"))
        }
        return decoder
    }
}

// MARK: - Paywall

/// What the reader is entitled to. Derived from the account state.
public enum Entitlement: Equatable, Sendable {
    case anonymous      // not logged in
    case registered     // logged in, no subscription
    case subscriber     // PLUS subscription
}

/// Single decision point for "tap on an article": free content opens; PLUS content opens only for subscribers.
public enum ArticleAccess: Equatable, Sendable {
    case open(URL)
    case paywall(URL)

    public static func decide(url: URL, isPremium: Bool, entitlement: Entitlement) -> ArticleAccess {
        isPremium && entitlement != .subscriber ? .paywall(url) : .open(url)
    }
}
