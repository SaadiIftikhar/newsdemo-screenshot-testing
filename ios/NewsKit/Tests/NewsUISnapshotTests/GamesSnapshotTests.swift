import Account
import AppShell
import Games
import NewsCore
import NewsFixtures
import NewsUI
import SnapshotTesting
import SwiftUI
import XCTest

/// Games tab: the list and each game in its key states (new, in progress, finished).
@MainActor
final class GamesSnapshotTests: XCTestCase {
    private func onScreen(_ view: some View) -> some View { NavigationStack { view } }

    func test_gamesList() {
        assertScreen(GamesHome())
    }

    func test_ticTacToe_new() {
        assertScreen(onScreen(TicTacToeView()), variants: [.light, .dark])
    }

    func test_ticTacToe_inProgress() {
        assertScreen(onScreen(TicTacToeView(game: TicTacToe(board: [.x, nil, nil, nil, .o, nil, nil, nil, .x]))),
                     variants: [.light])
    }

    func test_ticTacToe_won() {
        assertScreen(onScreen(TicTacToeView(game: TicTacToe(board: [.x, .x, .x, .o, .o, nil, nil, nil, nil]))),
                     variants: [.light, .dark])
    }

    func test_pairs_new() {
        assertScreen(onScreen(PairsView(game: PairsGame(seed: 42))), variants: [.light, .dark])
    }

    func test_pairs_inProgress() {
        var game = PairsGame(seed: 42)
        let first = game.cards[0].symbol
        let partner = game.cards.indices.first { $0 != 0 && game.cards[$0].symbol == first }!
        game.flip(0); game.flip(partner)                       // one matched pair
        let a = game.cards.indices.first { !game.cards[$0].isMatched }!
        let b = game.cards.indices.first { !game.cards[$0].isMatched && game.cards[$0].symbol != game.cards[a].symbol }!
        game.flip(a); game.flip(b)                             // one visible mismatch
        assertScreen(onScreen(PairsView(game: game)), variants: [.light])
    }

    func test_pairs_complete() {
        var game = PairsGame(seed: 42)
        for symbol in PairsGame.symbols {
            for index in game.cards.indices where game.cards[index].symbol == symbol { game.flip(index) }
        }
        assertScreen(onScreen(PairsView(game: game)), variants: [.light])
    }

    func test_sudoku_new() {
        assertScreen(onScreen(MiniSudokuView()), variants: [.light, .dark])
    }

    func test_sudoku_conflict() {
        var game = MiniSudoku()
        game.select(1); game.enter(4)
        assertScreen(onScreen(MiniSudokuView(game: game)), variants: [.light])
    }

    func test_sudoku_solved() {
        var game = MiniSudoku()
        let solution = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1]
        for index in solution.indices where !game.given[index] { game.select(index); game.enter(solution[index]) }
        assertScreen(onScreen(MiniSudokuView(game: game)), variants: [.light])
    }
}
