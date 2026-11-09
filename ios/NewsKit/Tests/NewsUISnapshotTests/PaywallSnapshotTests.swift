import NewsCore
import NewsUI
import SnapshotTesting
import SwiftUI
import XCTest

/// The paywall shown for PLUS articles. Revenue-critical, so it gets light, dark and large-text goldens.
@MainActor
final class PaywallSnapshotTests: XCTestCase {

    func test_paywall_anonymous() {
        assertScreen(PaywallView(entitlement: .anonymous))
    }

    /// Logged in without a subscription: no "Bereits Abonnent? Anmelden" link.
    func test_paywall_registered() {
        assertScreen(PaywallView(entitlement: .registered), variants: [.light])
    }
}
