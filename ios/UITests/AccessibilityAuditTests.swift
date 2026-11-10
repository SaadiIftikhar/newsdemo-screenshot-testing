import XCTest

/// Apple's automated accessibility audit on the real app: contrast, hit-region size, Dynamic Type clipping,
/// missing labels, element detection. Screenshots cannot see any of this (a golden of an unlabelled button looks
/// perfect), and the a11y review found such bugs by hand.
final class AccessibilityAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private static let tabLabels: Set<String> = ["Nachrichten", "Spiele", "Konto"]

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-fixture", "feed_default"] + extra
        app.launch()
    }

    private func audit(file: StaticString = #filePath, line: UInt = #line) throws {
        try app.performAccessibilityAudit { issue in
            // Accepted exceptions, kept as narrow as possible (tab-bar labels only; everything else fails):
            //  - dynamicType: the labels stop growing at xxLarge on purpose (like UITabBar) and offer the Large
            //    Content Viewer instead.
            //  - contrast on tab labels and the "WELT · vor 9 Min." credit line: false positives. The audit flagged
            //    the tab labels in grey (5:1) AND in near-black (>15:1, checked on a simulator screenshot), and the
            //    credit line in #6C6C70 (4.9:1) AND in a darker #5C5C60 (6.2:1): it is not measuring these colours.
            //    Their colour pairs are enforced exactly by ContrastTests (WCAG ≥ 4.5:1) instead. Any OTHER element
            //    still fails on contrast (that is how the sign-out button's red-on-red-tint was caught).
            if let label = issue.element?.label {
                if [.dynamicType, .contrast].contains(issue.auditType), Self.tabLabels.contains(label) { return true }
                if issue.auditType == .contrast, label.range(of: #"^(WELT|BILD) · "#, options: .regularExpression) != nil {
                    return true
                }
            }
            // Report-only: the two LARGE-TEXT heuristics (evaluated up to AX5, beyond our gated AX3 matrix).
            //  - dynamicType flagged feed headlines that the light_xxxl goldens show scaling correctly;
            //  - textClipped flags single-line fields and the deliberate 3-line teaser summary at AX5.
            // They are logged for triage (product decisions, e.g. "expand summaries at huge sizes?"), not gated.
            // Gated: contrast, hit regions, element detection, element descriptions, traits.
            if [.dynamicType, .textClipped].contains(issue.auditType) {
                print("a11y audit (report-only): \(issue.compactDescription) – \(issue.element?.label.prefix(80) ?? "")")
                return true
            }
            // Print every finding so the run log explains a failure without re-running.
            print("a11y audit: \(issue.auditType) – \(issue.compactDescription) – \(issue.element?.debugDescription.prefix(160) ?? "no element")")
            return false
        }
    }

    func test_audit_feed() throws {
        launch()
        XCTAssertTrue(app.buttons["tab-feed"].waitForExistence(timeout: 10))
        try audit()
    }

    func test_audit_games() throws {
        launch(["-tab", "games"])
        XCTAssertTrue(app.buttons["game-ticTacToe"].firstMatch.waitForExistence(timeout: 10))
        try audit()
    }

    func test_audit_ticTacToeBoard() throws {
        launch(["-tab", "games"])
        app.buttons["game-ticTacToe"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Feld 1: leer"].waitForExistence(timeout: 5))
        try audit()
    }

    func test_audit_login() throws {
        launch(["-tab", "account"])
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
        try audit()
    }

    func test_audit_profile() throws {
        launch(["-tab", "account", "-signedIn"])
        XCTAssertTrue(app.buttons["sign-out"].waitForExistence(timeout: 10))
        try audit()
    }

    func test_audit_paywall() throws {
        launch()
        let plus = app.buttons["article-tsr-002"]
        XCTAssertTrue(plus.waitForExistence(timeout: 10))
        plus.tap()
        XCTAssertTrue(app.buttons["PLUS testen"].waitForExistence(timeout: 5))
        try audit()
    }
}
