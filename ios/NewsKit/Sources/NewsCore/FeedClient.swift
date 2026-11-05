import Foundation

public enum FeedError: Error, Equatable, Sendable {
    case offline
    case server(status: Int)
    case decoding
}

/// The network seam. Production code depends on this value type, never on URLSession directly,
/// so tests/the app's mock mode can swap the implementation (same idea as a TCA `@DependencyClient`).
public struct FeedClient: Sendable {
    public var fetchFeed: @Sendable () async throws -> Feed

    public init(fetchFeed: @escaping @Sendable () async throws -> Feed) {
        self.fetchFeed = fetchFeed
    }
}

extension FeedClient {
    public static func live(baseURL: URL, session: URLSession = .shared) -> FeedClient {
        FeedClient {
            let url = baseURL.appendingPathComponent("feed.json")
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(from: url)
            } catch let error as URLError where [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed].contains(error.code) {
                throw FeedError.offline
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw FeedError.server(status: http.statusCode)
            }
            do {
                return try NewsDecoder.make().decode(Feed.self, from: data)
            } catch {
                throw FeedError.decoding
            }
        }
    }

    public static func failing(_ error: FeedError) -> FeedClient {
        FeedClient { throw error }
    }
}
