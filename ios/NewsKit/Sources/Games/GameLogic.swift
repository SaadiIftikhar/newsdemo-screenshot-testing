import Foundation

// Pure game rules: no UI, no randomness without a seed, so every state is reproducible in tests.
// A seeded RNG makes every shuffle reproducible: the same seed always gives the same board (tests pin it).

// MARK: - Catalog

public enum GameKind: String, CaseIterable, Identifiable, Sendable {
    case ticTacToe, pairs, sudoku
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .ticTacToe: "Tic-Tac-Toe"
        case .pairs: "Paare finden"
        case .sudoku: "Mini-Sudoku"
        }
    }

    public var subtitle: String {
        switch self {
        case .ticTacToe: "Drei in einer Reihe – gegen den Computer"
        case .pairs: "Decke alle passenden Kartenpaare auf"
        case .sudoku: "4 × 4: jede Zahl einmal pro Zeile, Spalte und Block"
        }
    }
}

// MARK: - Tic-Tac-Toe

public enum Mark: String, Sendable { case x = "X", o = "O" }

public struct TicTacToe: Equatable, Sendable {
    public private(set) var board: [Mark?]

    public static let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

    public init(board: [Mark?] = Array(repeating: nil, count: 9)) {
        precondition(board.count == 9)
        self.board = board
    }

    public var winningLine: [Int]? {
        Self.lines.first { line in board[line[0]] != nil && line.allSatisfy { board[$0] == board[line[0]] } }
    }
    public var winner: Mark? { winningLine.flatMap { board[$0[0]] } }
    public var isDraw: Bool { winner == nil && !board.contains(nil) }
    public var isOver: Bool { winner != nil || isDraw }
    public var nextPlayer: Mark { board.filter { $0 == .x }.count == board.filter { $0 == .o }.count ? .x : .o }

    @discardableResult
    public mutating func play(_ index: Int) -> Bool {
        guard !isOver, board.indices.contains(index), board[index] == nil else { return false }
        board[index] = nextPlayer
        return true
    }

    /// Human plays X; the computer answers immediately with O.
    public mutating func playAgainstComputer(_ index: Int) {
        guard nextPlayer == .x, play(index), !isOver, let reply = bestMove(for: .o) else { return }
        play(reply)
    }

    /// Deterministic strategy: win, block, centre, corner, side.
    public func bestMove(for mark: Mark) -> Int? {
        let opponent: Mark = mark == .x ? .o : .x
        func completing(_ m: Mark) -> Int? {
            for line in Self.lines {
                let marks = line.map { board[$0] }
                if marks.filter({ $0 == m }).count == 2, let empty = line.first(where: { board[$0] == nil }) { return empty }
            }
            return nil
        }
        if let win = completing(mark) { return win }
        if let block = completing(opponent) { return block }
        return ([4] + [0, 2, 6, 8] + [1, 3, 5, 7]).first { board[$0] == nil }
    }
}

// MARK: - Pairs (memory-style card matching)

/// SplitMix64: tiny, well-known PRNG, portable to any platform → the same shuffle per seed everywhere.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public struct PairsGame: Equatable, Sendable {
    public struct Card: Equatable, Sendable, Identifiable {
        public let id: Int
        public let symbol: String
        public var isFaceUp = false
        public var isMatched = false
    }

    public static let symbols = ["star", "heart", "diamond", "club", "spade", "circle"]

    public private(set) var cards: [Card]
    public private(set) var moves = 0

    public init(seed: UInt64) {
        var deck = Self.symbols + Self.symbols
        var rng = SplitMix64(seed: seed)
        // Explicit Fisher–Yates (not `shuffle(using:)`), so another platform can reproduce it exactly.
        var i = deck.count - 1
        while i > 0 {
            let j = Int(rng.next() % UInt64(i + 1))
            deck.swapAt(i, j)
            i -= 1
        }
        cards = deck.enumerated().map { Card(id: $0.offset, symbol: $0.element) }
    }

    public var isComplete: Bool { cards.allSatisfy(\.isMatched) }

    /// Rules without timers (deterministic): a mismatched pair stays visible until the next flip.
    public mutating func flip(_ index: Int) {
        guard cards.indices.contains(index), !cards[index].isFaceUp, !cards[index].isMatched else { return }
        let open = cards.indices.filter { cards[$0].isFaceUp && !cards[$0].isMatched }
        if open.count == 2 { open.forEach { cards[$0].isFaceUp = false } }
        cards[index].isFaceUp = true
        let nowOpen = cards.indices.filter { cards[$0].isFaceUp && !cards[$0].isMatched }
        if nowOpen.count == 2 {
            moves += 1
            if cards[nowOpen[0]].symbol == cards[nowOpen[1]].symbol {
                nowOpen.forEach { cards[$0].isMatched = true }
            }
        }
    }
}

// MARK: - Mini-Sudoku (4 × 4)

public struct MiniSudoku: Equatable, Sendable {
    /// 0 = empty. Solution: 1234 / 3412 / 2143 / 4321.
    public static let puzzle = [1, 0, 0, 4,
                                0, 4, 1, 0,
                                0, 1, 4, 0,
                                4, 0, 0, 1]

    public private(set) var cells: [Int]
    public let given: [Bool]
    public private(set) var selected: Int?

    public init(puzzle: [Int] = MiniSudoku.puzzle) {
        cells = puzzle
        given = puzzle.map { $0 != 0 }
    }

    public mutating func select(_ index: Int) {
        guard cells.indices.contains(index), !given[index] else { return }
        selected = index
    }

    /// Enter 1–4 into the selected cell; 0 clears it.
    public mutating func enter(_ value: Int) {
        guard let selected, (0...4).contains(value) else { return }
        cells[selected] = value
    }

    /// Indices of cells whose value repeats in their row, column or 2 × 2 block.
    public var conflicts: Set<Int> {
        var result = Set<Int>()
        for i in cells.indices where cells[i] != 0 {
            for j in cells.indices where j != i && cells[j] == cells[i] {
                let sameRow = i / 4 == j / 4
                let sameColumn = i % 4 == j % 4
                let sameBlock = (i / 8 == j / 8) && ((i % 4) / 2 == (j % 4) / 2)
                if sameRow || sameColumn || sameBlock { result.insert(i) }
            }
        }
        return result
    }

    public var isSolved: Bool { !cells.contains(0) && conflicts.isEmpty }
}
