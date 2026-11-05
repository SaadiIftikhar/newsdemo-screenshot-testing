import Account
import AppShell
import Games
import NewsCore
import NewsFixtures
import NewsUI
import SnapshotTesting
import SwiftUI
import XCTest

/// Account tab: login states and the signed-in profile.
@MainActor
final class AccountSnapshotTests: XCTestCase {

    func test_login_empty() {
        assertScreen(AccountScreen(model: AccountViewModel()))
    }

    func test_login_validationErrors() async {
        let model = AccountViewModel(email: "kein-at", password: "kurz")
        await model.signIn()
        assertScreen(AccountScreen(model: model), variants: [.light])
    }

    func test_login_wrongCredentials() async {
        let model = AccountViewModel(client: .demo, email: AuthClient.demoEmail, password: "falsch123")
        await model.signIn()
        assertScreen(AccountScreen(model: model), variants: [.light])
    }

    func test_profile_signedIn() {
        let profile = UserProfile(name: "Demo Leser", email: AuthClient.demoEmail, isPremium: true)
        assertScreen(AccountScreen(model: AccountViewModel(state: .signedIn(profile))), variants: [.light, .dark])
    }
}
