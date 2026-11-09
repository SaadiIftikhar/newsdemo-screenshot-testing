import NewsUI
import SwiftUI

// MARK: - Games tab

/// The Games tab: a list of playable games, each pushing its own screen.
public struct GamesHome: View {
    @State private var path: [GameKind]
    /// Fixture mode / Layer 2 pins the pairs deal via `-pairsSeed`; real users get a random deal.
    @Environment(\.pairsSeed) private var pairsSeed

    public init(path: [GameKind] = []) { _path = State(initialValue: path) }

    public var body: some View {
        NavigationStack(path: $path) {
            GamesList()
                .navigationTitle("Spiele")
                .navigationDestination(for: GameKind.self) { kind in
                    switch kind {
                    case .ticTacToe: TicTacToeView()
                    case .pairs: PairsView(game: PairsGame(seed: pairsSeed ?? UInt64.random(in: 1...UInt64.max)))
                    case .sudoku: MiniSudokuView()
                    }
                }
        }
    }
}

public struct GamesList: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: NewsTheme.spacing) {
                Text("Kurze Pause gefällig? Drei Klassiker, offline spielbar.")
                    .font(.subheadline)
                    .foregroundStyle(NewsTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(GameKind.allCases) { kind in
                    NavigationLink(value: kind) { GameCard(kind: kind) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("game-\(kind.rawValue)")
                }
            }
            .padding(NewsTheme.spacing)
        }
        .background(NewsTheme.background)
    }
}

struct GameCard: View {
    let kind: GameKind

    var body: some View {
        HStack(spacing: NewsTheme.spacing) {
            Image(systemName: kind.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(kind.tint, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title).font(.headline).foregroundStyle(NewsTheme.textPrimary)
                Text(kind.subtitle).font(.subheadline).foregroundStyle(NewsTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(NewsTheme.textSecondary)
        }
        .padding(NewsTheme.spacing)
        .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
        .accessibilityElement(children: .combine)
    }
}

extension GameKind {
    var symbol: String {
        switch self {
        case .ticTacToe: "number"
        case .pairs: "square.grid.2x2.fill"
        case .sudoku: "square.grid.3x3.fill"
        }
    }

    var tint: Color {
        switch self {
        case .ticTacToe: NewsTheme.breakingRed
        case .pairs: Color(red: 0.16, green: 0.42, blue: 0.78)
        case .sudoku: Color(red: 0.05, green: 0.50, blue: 0.36)
        }
    }
}

// MARK: - Tic-Tac-Toe

public struct TicTacToeView: View {
    @State private var game: TicTacToe

    public init(game: TicTacToe = TicTacToe()) { _game = State(initialValue: game) }

    private var status: String {
        if let winner = game.winner { return winner == .x ? "Du hast gewonnen!" : "Der Computer hat gewonnen." }
        if game.isDraw { return "Unentschieden." }
        return "Du spielst X – du bist dran."
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text(status).font(.title3.weight(.bold)).foregroundStyle(NewsTheme.textPrimary)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { column in cell(row * 3 + column) }
                    }
                }
            }
            // Explicit width: a Grid with only maxWidth collapsed to its content (≈173pt vs 293dp on Android).
            .containerRelativeFrame(.horizontal) { width, _ in min(width - 2 * NewsTheme.spacing, 320) }
            Button("Neues Spiel") { game = TicTacToe() }
                .buttonStyle(.borderedProminent)
                .tint(NewsTheme.breakingRed)
        }
        .padding(NewsTheme.spacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NewsTheme.background)
        .navigationTitle("Tic-Tac-Toe")
    }

    private func cell(_ index: Int) -> some View {
        let isWinning = game.winningLine?.contains(index) ?? false
        return Button { game.playAgainstComputer(index) } label: {
            Text(game.board[index]?.rawValue ?? " ")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(game.board[index] == .x ? NewsTheme.accentText : NewsTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(isWinning ? NewsTheme.premiumGold.opacity(0.35) : NewsTheme.card,
                            in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Feld \(index + 1): \(game.board[index]?.rawValue ?? "leer")\(isWinning ? ", Gewinnreihe" : "")")
    }
}

// MARK: - Pairs

public struct PairsView: View {
    @State private var game: PairsGame

    public init(game: PairsGame) { _game = State(initialValue: game) }

    public var body: some View {
        VStack(spacing: 16) {
            Text(game.isComplete ? "Geschafft in \(game.moves) Zügen!" : "Züge: \(game.moves)")
                .font(.title3.weight(.bold))
                .foregroundStyle(NewsTheme.textPrimary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(game.cards.indices, id: \.self) { index in card(index) }
            }
            .frame(maxWidth: 360)
        }
        .padding(NewsTheme.spacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NewsTheme.background)
        .navigationTitle("Paare finden")
    }

    private func card(_ index: Int) -> some View {
        let card = game.cards[index]
        let visible = card.isFaceUp || card.isMatched
        return Button { game.flip(index) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(visible ? NewsTheme.card : Color(red: 0.16, green: 0.42, blue: 0.78))
                if visible {
                    Image(systemName: Self.icon(card.symbol))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(card.isMatched ? NewsTheme.textSecondary : NewsTheme.accentText)
                } else {
                    Image(systemName: "questionmark").font(.title2.weight(.bold)).foregroundStyle(.white.opacity(0.8))
                }
            }
            .aspectRatio(0.8, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(visible ? Self.spokenName(card.symbol) + (card.isMatched ? ", gefunden" : "") : "Verdeckte Karte")
    }

    static func spokenName(_ symbol: String) -> String {
        ["star": "Stern", "heart": "Herz", "diamond": "Karo", "club": "Kreuz", "spade": "Pik"][symbol] ?? "Kreis"
    }

    static func icon(_ symbol: String) -> String {
        switch symbol {
        case "star": "star.fill"
        case "heart": "heart.fill"
        case "diamond": "suit.diamond.fill"
        case "club": "suit.club.fill"
        case "spade": "suit.spade.fill"
        default: "circle.fill"
        }
    }
}

// MARK: - Mini-Sudoku

public struct MiniSudokuView: View {
    @State private var game: MiniSudoku

    public init(game: MiniSudoku = MiniSudoku()) { _game = State(initialValue: game) }

    public var body: some View {
        VStack(spacing: 20) {
            Text(game.isSolved ? "Gelöst!" : (game.conflicts.isEmpty ? "Feld wählen, dann Zahl tippen." : "Da passt etwas nicht."))
                .font(.title3.weight(.bold))
                .foregroundStyle(game.conflicts.isEmpty ? NewsTheme.textPrimary : NewsTheme.accentText)
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(0..<4, id: \.self) { row in
                    GridRow {
                        ForEach(0..<4, id: \.self) { column in cell(row * 4 + column) }
                    }
                }
            }
            .containerRelativeFrame(.horizontal) { width, _ in min(width - 2 * NewsTheme.spacing, 300) }
            HStack(spacing: 10) {
                ForEach(1...4, id: \.self) { value in
                    // ≥ 44pt touch targets (they were ≈38pt).
                    Button { game.enter(value) } label: {
                        Text("\(value)").font(.title3.weight(.bold)).frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
                Button { game.enter(0) } label: {
                    Image(systemName: "delete.left").frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Löschen")
            }
            .tint(NewsTheme.textPrimary)
        }
        .padding(NewsTheme.spacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(NewsTheme.background)
        .navigationTitle("Mini-Sudoku")
    }

    private func cell(_ index: Int) -> some View {
        let value = game.cells[index]
        let isConflict = game.conflicts.contains(index)
        let row = index / 4, column = index % 4
        let shaded = (row / 2 + column / 2) % 2 == 0
        return Button { game.select(index) } label: {
            Text(value == 0 ? " " : "\(value)")
                .font(.system(size: 30, weight: game.given[index] ? .heavy : .regular, design: .rounded))
                .foregroundStyle(isConflict ? NewsTheme.accentText : NewsTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(shaded ? NewsTheme.card : NewsTheme.adBackground, in: RoundedRectangle(cornerRadius: 6))
                .overlay {
                    if game.selected == index {
                        RoundedRectangle(cornerRadius: 6).stroke(NewsTheme.breakingRed, lineWidth: 3)
                    }
                }
        }
        .buttonStyle(.plain)
        // State in words, not only colour/weight (WCAG 1.4.1): given, conflict and selection are spoken.
        .accessibilityLabel("Zeile \(row + 1), Spalte \(column + 1): \(value == 0 ? "leer" : "\(value)")"
            + (game.given[index] ? ", vorgegeben" : "") + (isConflict ? ", Konflikt" : ""))
        .accessibilityAddTraits(game.selected == index ? .isSelected : [])
    }
}
