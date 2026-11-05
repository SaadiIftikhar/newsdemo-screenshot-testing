import Account
import Games
import NewsCore
import NewsFixtures
import XCTest

/// Behaviour tests for the new screens' logic. Snapshots prove how a state LOOKS;
/// these prove the app GETS into the right state. Mirrored 1:1 in the Android suite.
final class GameLogicTests: XCTestCase {

    func test_ticTacToe_detectsRowColumnAndDiagonalWins() {
        XCTAssertEqual(TicTacToe(board: [.x, .x, .x, nil, .o, .o, nil, nil, nil]).winner, .x)
        XCTAssertEqual(TicTacToe(board: [.o, .x, nil, .o, .x, nil, .o, nil, .x]).winner, .o)
        XCTAssertEqual(TicTacToe(board: [.x, .o, nil, .o, .x, nil, nil, nil, .x]).winningLine, [0, 4, 8])
    }

    func test_ticTacToe_detectsDraw() {
        let game = TicTacToe(board: [.x, .o, .x, .x, .o, .o, .o, .x, .x])
        XCTAssertNil(game.winner)
        XCTAssertTrue(game.isDraw)
    }

    func test_ticTacToe_computerWinsThenBlocksThenTakesCentre() {
        XCTAssertEqual(TicTacToe(board: [.o, .o, nil, .x, .x, nil, .x, nil, nil]).bestMove(for: .o), 2)  // win
        XCTAssertEqual(TicTacToe(board: [.x, .x, nil, nil, .o, nil, nil, nil, nil]).bestMove(for: .o), 2) // block
        XCTAssertEqual(TicTacToe().bestMove(for: .o), 4)                                                   // centre
    }

    func test_ticTacToe_computerAnswersEveryHumanMove() {
        var game = TicTacToe()
        game.playAgainstComputer(0)
        XCTAssertEqual(game.board[0], .x)
        XCTAssertEqual(game.board[4], .o)
        game.playAgainstComputer(0) // occupied: ignored
        XCTAssertEqual(game.board.compactMap { $0 }.count, 2)
    }

    func test_pairs_sameSeedGivesSameLayout_andAllPairsArePresent() {
        XCTAssertEqual(PairsGame(seed: 42).cards.map(\.symbol), PairsGame(seed: 42).cards.map(\.symbol))
        XCTAssertNotEqual(PairsGame(seed: 42).cards.map(\.symbol), PairsGame(seed: 7).cards.map(\.symbol))
        let counts = Dictionary(grouping: PairsGame(seed: 42).cards, by: \.symbol).mapValues(\.count)
        XCTAssertEqual(counts.count, 6)
        XCTAssertTrue(counts.values.allSatisfy { $0 == 2 })
    }

    /// Pins the shuffle so Android can assert the very same order (cross-platform parity).
    func test_pairs_seed42Layout() {
        XCTAssertEqual(PairsGame(seed: 42).cards.map(\.symbol), PairsLayout.seed42)
    }

    func test_pairs_matchMismatchAndCompletion() {
        var game = PairsGame(seed: 42)
        let first = game.cards[0].symbol
        let partner = game.cards.indices.first { $0 != 0 && game.cards[$0].symbol == first }!
        let other = game.cards.indices.first { game.cards[$0].symbol != first }!

        game.flip(0); game.flip(other)                    // mismatch stays visible...
        XCTAssertEqual(game.moves, 1)
        XCTAssertTrue(game.cards[0].isFaceUp && game.cards[other].isFaceUp)
        game.flip(partner)                                 // ...until the next flip hides it
        XCTAssertFalse(game.cards[other].isFaceUp)
        game.flip(0)
        XCTAssertTrue(game.cards[0].isMatched && game.cards[partner].isMatched)

        for symbol in PairsGame.symbols {
            for index in game.cards.indices where game.cards[index].symbol == symbol { game.flip(index) }
        }
        XCTAssertTrue(game.isComplete)
    }

    func test_sudoku_conflictsAndSolution() {
        var game = MiniSudoku()
        game.select(0)                     // a given cell cannot be selected
        XCTAssertNil(game.selected)
        game.select(1); game.enter(4)      // 4 already in row 0
        XCTAssertTrue(game.conflicts.contains(1))
        XCTAssertFalse(game.isSolved)

        let solution = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1]
        for index in solution.indices where !game.given[index] { game.select(index); game.enter(solution[index]) }
        XCTAssertTrue(game.conflicts.isEmpty)
        XCTAssertTrue(game.isSolved)
    }
}

/// Layout produced by SplitMix64 + Fisher–Yates for seed 42 (asserted on both platforms).
enum PairsLayout {
    /// Computed independently (Python reference implementation of the same algorithm).
    static let seed42 = ["club", "star", "heart", "spade", "club", "circle",
                         "spade", "diamond", "star", "diamond", "circle", "heart"]
}

@MainActor
final class AccountLogicTests: XCTestCase {

    func test_validation() {
        XCTAssertEqual(LoginValidator.validate(email: "", password: "").email, "Bitte E-Mail-Adresse eingeben.")
        XCTAssertEqual(LoginValidator.validate(email: "kein-at", password: "12345678").email,
                       "Bitte eine gültige E-Mail-Adresse eingeben.")
        XCTAssertEqual(LoginValidator.validate(email: "a@b.de", password: "kurz").password,
                       "Das Passwort hat mindestens 8 Zeichen.")
        XCTAssertTrue(LoginValidator.validate(email: "a@b.de", password: "12345678").isEmpty)
    }

    func test_signIn_invalidInput_neverCallsBackend() async {
        let model = AccountViewModel(client: AuthClient { _, _ in XCTFail("backend called"); throw AuthError.offline },
                                     email: "falsch", password: "")
        await model.signIn()
        XCTAssertEqual(model.state, .signedOut)
        XCTAssertNotNil(model.fieldErrors.email)
    }

    func test_signIn_demoAccount_thenSignOut() async {
        let model = AccountViewModel(client: .demo, email: AuthClient.demoEmail, password: AuthClient.demoPassword)
        await model.signIn()
        guard case .signedIn(let profile) = model.state else { return XCTFail("expected signed in") }
        XCTAssertTrue(profile.isPremium)
        XCTAssertEqual(model.password, "", "password must not linger in memory after sign-in")
        model.signOut()
        XCTAssertEqual(model.state, .signedOut)
    }

    func test_signIn_wrongPassword_andOffline() async {
        let wrong = AccountViewModel(client: .demo, email: AuthClient.demoEmail, password: "falsch123")
        await wrong.signIn()
        XCTAssertEqual(wrong.state, .failed("E-Mail-Adresse oder Passwort ist falsch."))
        let offline = AccountViewModel(client: .failing(.offline), email: AuthClient.demoEmail, password: "12345678")
        await offline.signIn()
        XCTAssertEqual(offline.state, .failed("Keine Internetverbindung. Bitte später erneut versuchen."))
    }
}

/// Link-out contract: every real headline opens its publisher page over HTTPS and credits the source.
final class LinkOutContractTests: XCTestCase {
    func test_defaultFeed_everyArticleLinksOutOverHTTPS_withSource() throws {
        let feed = try FixtureStore.repository().feed("feed_default")
        let breaking = try XCTUnwrap(feed.breaking)
        XCTAssertEqual(breaking.url?.scheme, "https")
        XCTAssertNotNil(breaking.source)
        let linkable = feed.items.filter { if case .ad = $0 { false } else { true } }
        for item in linkable {
            XCTAssertEqual(item.articleURL?.scheme, "https", "\(item.id) must link out over HTTPS")
            XCTAssertTrue(["welt.de", "bild.de"].contains { item.articleURL?.host?.hasSuffix($0) == true }, item.id)
        }
    }
}
