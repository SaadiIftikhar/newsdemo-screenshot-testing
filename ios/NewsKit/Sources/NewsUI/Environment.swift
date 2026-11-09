import SwiftUI
import UIKit

// Every source of non-determinism the UI touches is an injectable environment value.
// Production uses the live defaults; snapshot tests pin them.

public enum ImageProvider: Sendable {
    /// Production: load asynchronously from the CDN.
    case remote(baseURL: URL)
    /// Tests / mock mode: resolve synchronously from local files, so the first render already has pixels.
    case local(@Sendable (String) -> UIImage?)
}

extension EnvironmentValues {
    /// "Now" used for relative timestamps ("vor 8 Min."). Live: Date(); tests: a fixed instant.
    @Entry public var now: Date = Date()
    @Entry public var imageProvider: ImageProvider = .remote(baseURL: URL(string: "https://cdn.example.com/img/")!)
    /// Live tickers pulse. Tests switch this off so the frame captured is always the same.
    @Entry public var animationsEnabled: Bool = true
    /// Pins the pairs deal (tests / fixture mode). Nil = random.
    @Entry public var pairsSeed: UInt64? = nil
}
