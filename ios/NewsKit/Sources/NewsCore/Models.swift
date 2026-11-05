import Foundation

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
        breaking = try container.decodeIfPresent(BreakingNews.self, forKey: .breaking)
        // Unknown item types are dropped instead of failing the whole feed (forward compatibility).
        items = try container.decode([FeedItem].self, forKey: .items).filter { $0 != .unsupported }
    }
}

public struct BreakingNews: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var headline: String
    public var publishedAt: Date
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

    enum TypeKey: String, CodingKey { case type }

    public init(from decoder: any Decoder) throws {
        let type = try decoder.container(keyedBy: TypeKey.self).decode(String.self, forKey: .type)
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

    enum CodingKeys: String, CodingKey {
        case id, kicker, headline, summary, image, publishedAt
        case isPremium = "premium"
    }
}

public struct LiveTicker: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var kicker: String
    public var headline: String
    public var latestUpdate: String
    public var updatedAt: Date
}

public struct VideoTeaser: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var kicker: String
    public var headline: String
    public var image: String
    public var durationSeconds: Int
    public var publishedAt: Date
}

public struct AdSlot: Equatable, Sendable, Decodable, Identifiable {
    public var id: String
    public var slot: String
    public var height: Double
}

public enum NewsDecoder {
    /// The single decoder used in production AND by fixtures — so fixtures also exercise real parsing.
    public static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
