import XCTest

/// Behaviour, not pixels: drives the real app on the pinned simulator
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

    /// Regression guard: the board must survive switching tabs.
    func test_gameProgress_survivesSwitchingTabs() {
        launch(["-tab", "games"])
        app.buttons["game-ticTacToe"].firstMatch.tap()
        app.buttons["Feld 1: leer"].tap()
        app.buttons["tab-feed"].tap()
        app.buttons["tab-games"].tap()
        XCTAssertTrue(app.buttons["Feld 1: X"].waitForExistence(timeout: 5))
    }

    func test_account_invalidInput_showsFieldErrors() {
        launch(["-tab", "account", "-emptyLogin"])
        app.buttons["sign-in"].tap()
        XCTAssertTrue(app.staticTexts["Bitte E-Mail-Adresse eingeben."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bitte Passwort eingeben."].exists)
    }

    func test_account_signInWithDemoUser_showsProfile_thenSignOut() {
        launch(["-tab", "account"])
        // The demo app pre-fills the demo account: one tap signs in.
        XCTAssertEqual(app.textFields["email"].value as? String, "demo@newsdemo.app")
        app.buttons["sign-in"].tap()
        XCTAssertTrue(app.staticTexts["Demo Leser"].waitForExistence(timeout: 5))
        app.buttons["sign-out"].tap()
        XCTAssertTrue(app.buttons["sign-in"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["email"].value as? String, "demo@newsdemo.app") // ready for the next sign-in
    }

    // Never tap or assert before the element is there: the first CI runs showed these tests racing the sheet
    // animation on a slower runner (they always passed on a laptop). Wait explicitly, never retry.
    private func tapWhenReady(_ element: XCUIElement, timeout: TimeInterval = 15,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(element) never appeared", file: file, line: line)
        element.tap()
    }

    private func waitUntilSelected(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isSelected == true"), object: element)
        return XCTWaiter.wait(for: [selected], timeout: timeout) == .completed
    }

    func test_tappingAPlusTeaser_whenLoggedOut_showsThePaywall_notTheArticle() {
        launch()
        tapWhenReady(app.buttons["article-tsr-002"]) // XCUITest scrolls it into view
        XCTAssertTrue(app.staticTexts["Weiterlesen mit PLUS"].waitForExistence(timeout: 10))
    }

    func test_paywallSignIn_switchesToTheAccountTab() {
        launch()
        tapWhenReady(app.buttons["article-tsr-002"])
        tapWhenReady(app.buttons["Bereits Abonnent? Anmelden"])
        XCTAssertTrue(app.buttons["sign-in"].waitForExistence(timeout: 10))
        XCTAssertTrue(waitUntilSelected(app.buttons["tab-account"]), "the Konto tab is selected after the sheet closes")
    }

    func test_tappingAPlusTeaser_asSubscriber_doesNotShowThePaywall() {
        launch(["-signedIn"])
        tapWhenReady(app.buttons["article-tsr-002"])
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
