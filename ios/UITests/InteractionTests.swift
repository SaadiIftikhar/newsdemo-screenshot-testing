import XCTest

/// Behaviour, not pixels: drives the real app on the pinned simulator, like Android's Robolectric InteractionTests
/// (same scenarios, same names where they exist on both). The app starts in fixture mode via launch arguments.
final class InteractionTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-fixture", "feed_default"] + extra
        app.launch()
    }

    func test_tabBar_switchesTabs_andMarksTheSelectedOne() {
        launch()
        XCTAssertTrue(app.buttons["tab-feed"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tab-feed"].isSelected)
        app.buttons["tab-games"].tap()
        XCTAssertTrue(app.buttons["tab-games"].isSelected)
        XCTAssertTrue(app.staticTexts["Kurze Pause gefällig? Drei Klassiker, offline spielbar."].waitForExistence(timeout: 5))
    }

    func test_games_openTicTacToe_humanMoveGetsComputerReply() {
        launch(["-tab", "games"])
        app.buttons["game-ticTacToe"].firstMatch.tap()
        app.buttons["Feld 1: leer"].tap()
        XCTAssertTrue(app.buttons["Feld 1: X"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Feld 5: O"].exists, "computer took the centre")
    }

    /// Regression guard (the bug was found on Android): the board must survive switching tabs.
    func test_gameProgress_survivesSwitchingTabs() {
        launch(["-tab", "games"])
        app.buttons["game-ticTacToe"].firstMatch.tap()
        app.buttons["Feld 1: leer"].tap()
        app.buttons["tab-feed"].tap()
        app.buttons["tab-games"].tap()
        XCTAssertTrue(app.buttons["Feld 1: X"].waitForExistence(timeout: 5))
    }

    func test_account_invalidInput_showsFieldErrors() {
        launch(["-tab", "account"])
        app.buttons["sign-in"].tap()
        XCTAssertTrue(app.staticTexts["Bitte E-Mail-Adresse eingeben."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bitte Passwort eingeben."].exists)
    }

    func test_account_signInWithDemoUser_showsProfile_thenSignOut() {
        launch(["-tab", "account"])
        let email = app.textFields["email"]
        email.tap(); email.typeText("demo@newsdemo.app")
        let password = app.secureTextFields["password"]
        password.tap(); password.typeText("demo1234")
        app.buttons["sign-in"].tap()
        XCTAssertTrue(app.staticTexts["Demo Leser"].waitForExistence(timeout: 5))
        app.buttons["sign-out"].tap()
        XCTAssertTrue(app.buttons["sign-in"].waitForExistence(timeout: 5))
    }

    func test_tappingAPlusTeaser_whenLoggedOut_showsThePaywall_notTheArticle() {
        launch()
        app.buttons["article-tsr-002"].tap() // XCUITest scrolls it into view
        XCTAssertTrue(app.staticTexts["Weiterlesen mit PLUS"].waitForExistence(timeout: 5))
    }

    func test_paywallSignIn_switchesToTheAccountTab() {
        launch()
        app.buttons["article-tsr-002"].tap()
        app.buttons["Bereits Abonnent? Anmelden"].tap()
        XCTAssertTrue(app.buttons["sign-in"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-account"].isSelected)
    }

    func test_tappingAPlusTeaser_asSubscriber_doesNotShowThePaywall() {
        launch(["-signedIn"])
        app.buttons["article-tsr-002"].tap()
        XCTAssertFalse(app.staticTexts["Weiterlesen mit PLUS"].waitForExistence(timeout: 3))
    }

    /// The connection drops after the first load; pull to refresh must keep the news and say since when.
    func test_pullToRefresh_whileOffline_keepsTheFeed_andShowsWhenItWasLoaded() {
        launch(["-dropConnection"])
        let article = app.buttons["article-tsr-001"]
        XCTAssertTrue(article.waitForExistence(timeout: 10))
        let start = app.staticTexts["NewsDemo"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 4))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 450)))
        XCTAssertTrue(app.staticTexts["Offline – gespeicherte Artikel"].waitForExistence(timeout: 10))
        XCTAssertTrue(article.exists, "the cached articles stay on screen")
    }
}
