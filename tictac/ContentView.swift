//
//  ContentView.swift
//  tictac
//
//  Created by David Glover on 25/4/2026.
//

import SwiftUI

struct ContentView: View {
    private static let boardSide = 5
    private static let winLength = 4
    private static let humanPlayer: Player = .x
    private static let computerPlayer: Player = .o

    @State private var board: [Player?] = Array(repeating: nil, count: 25)
    @State private var currentPlayer: Player = .x
    @State private var winner: Player?
    @State private var isDraw = false
    @State private var winningCells: Set<Int> = []
    @State private var isComputerThinking = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.95), Color.purple.opacity(0.82), Color.black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let contentWidth = min(max(proxy.size.width - 48, 340), 520)
                let boardSize = min(contentWidth, max(320, proxy.size.height - 350))

                VStack(spacing: 16) {
                    header
                    statusCard
                    boardView
                        .frame(width: boardSize)
                    resetButton
                }
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            }
        }
        .frame(minWidth: 520, minHeight: 680)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Tic-Tac-Four")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)

            Text("5×5 grid • you are X, computer is O")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: statusIcon)
                .font(.title2.weight(.bold))
                .foregroundStyle(statusColor)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(statusSubtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Text(currentPlayer.rawValue)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(currentPlayer.markColor)
                .opacity(winner == nil && !isDraw ? 1 : 0.35)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(16)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 14)
    }

    private var boardView: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(board.indices, id: \.self) { index in
                Button {
                    play(at: index)
                } label: {
                    cellView(at: index)
                }
                .buttonStyle(.plain)
                .disabled(!canPlay(at: index))
                .accessibilityLabel(accessibilityLabel(for: index))
            }
        }
        .padding(12)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 28, x: 0, y: 18)
    }

    private var resetButton: some View {
        Button(action: resetGame) {
            Label("New Game", systemImage: "arrow.clockwise")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .shadow(color: .cyan.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .keyboardShortcut("r", modifiers: [.command])
    }

    private func cellView(at index: Int) -> some View {
        let player = board[index]
        let isWinningCell = winningCells.contains(index)

        return ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cellFill(for: player, isWinningCell: isWinningCell))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(cellStroke(for: player, isWinningCell: isWinningCell), lineWidth: isWinningCell ? 4 : 1.5)
                }
                .shadow(color: cellShadow(for: player, isWinningCell: isWinningCell), radius: isWinningCell ? 18 : 8, x: 0, y: 8)

            if let player {
                Text(player.rawValue)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(player.markColor)
                    .shadow(color: player.markColor.opacity(0.28), radius: 10, x: 0, y: 6)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 10, height: 10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var statusTitle: String {
        if let winner {
            return winner == Self.humanPlayer ? "You win!" : "Computer wins"
        }

        if isDraw {
            return "It’s a draw"
        }

        if isComputerThinking {
            return "Computer is thinking…"
        }

        return "Your turn"
    }

    private var statusSubtitle: String {
        if let winner {
            return winner == Self.humanPlayer ? "Four in a row — you beat the machine." : "The computer connected four. Try another round."
        }

        if isDraw {
            return "The board is full. Try another round."
        }

        if isComputerThinking {
            return "The computer is looking for a win, a block, or the best setup."
        }

        return "Place an X and connect four horizontally, vertically, or diagonally."
    }

    private var statusIcon: String {
        if winner != nil { return "crown.fill" }
        if isDraw { return "equal.circle.fill" }
        if isComputerThinking { return "cpu.fill" }
        return "person.fill"
    }

    private var statusColor: Color {
        if let winner { return winner.markColor }
        if isDraw { return .orange }
        if isComputerThinking { return Self.computerPlayer.markColor }
        return Self.humanPlayer.markColor
    }

    private func canPlay(at index: Int) -> Bool {
        board[index] == nil && winner == nil && !isDraw && !isComputerThinking && currentPlayer == Self.humanPlayer
    }

    private func play(at index: Int) {
        guard canPlay(at: index) else { return }

        resolveMove(at: index, for: Self.humanPlayer)

        if winner == nil && !isDraw {
            scheduleComputerMove()
        }
    }

    private func resolveMove(at index: Int, for player: Player) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
            board[index] = player

            if let cells = winningLine(for: player) {
                winner = player
                winningCells = Set(cells)
            } else if board.allSatisfy({ $0 != nil }) {
                isDraw = true
            } else {
                currentPlayer = player.opponent
            }
        }
    }

    private func scheduleComputerMove() {
        isComputerThinking = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard isComputerThinking, winner == nil, !isDraw, currentPlayer == Self.computerPlayer else { return }

            if let move = bestComputerMove() {
                resolveMove(at: move, for: Self.computerPlayer)
            }

            isComputerThinking = false
        }
    }

    private func resetGame() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            board = Array(repeating: nil, count: Self.boardSide * Self.boardSide)
            currentPlayer = Self.humanPlayer
            winner = nil
            isDraw = false
            winningCells = []
            isComputerThinking = false
        }
    }

    // Maximum search depth (plies) for minimax look-ahead.
    private static let searchDepth = 5

    // Sentinel score representing a forced win/loss inside the search.
    private static let winScore = 1_000_000

    // Moves whose score is within this margin of the best are considered
    // equally good and chosen randomly between, to add variety.
    private static let moveTieMargin = 25

    private func bestComputerMove() -> Int? {
        let moves = availableMoves
        guard !moves.isEmpty else { return nil }

        // Fast paths: take an immediate win, or block an immediate loss.
        if let winningMove = firstWinningMove(for: Self.computerPlayer, in: moves) {
            return winningMove
        }

        if let blockingMove = firstWinningMove(for: Self.humanPlayer, in: moves) {
            return blockingMove
        }

        // Opening move on an empty board: pick randomly from a set of
        // strong central squares so the computer doesn't always start the
        // same way. Skipping the search here also keeps the first move snappy.
        if moves.count == Self.boardSide * Self.boardSide {
            let strongOpenings = [6, 7, 8, 11, 12, 13, 16, 17, 18] // inner 3×3
            return strongOpenings.randomElement()
        }

        // Search with iterative ordering: rank candidates by the static heuristic
        // first so alpha-beta prunes more aggressively.
        let candidates = candidateMoves(on: board)
            .sorted { scoreComputerMove($0) > scoreComputerMove($1) }

        // Score every candidate with full minimax, then pick randomly among
        // those within `moveTieMargin` of the best score.
        var scoredMoves: [(move: Int, score: Int)] = []
        scoredMoves.reserveCapacity(candidates.count)

        var bestScore = Int.min
        var alpha = Int.min
        let beta = Int.max
        var workingBoard = board

        for move in candidates {
            workingBoard[move] = Self.computerPlayer
            let score = minimax(
                board: &workingBoard,
                depth: Self.searchDepth - 1,
                alpha: alpha,
                beta: beta,
                maximizing: false
            )
            workingBoard[move] = nil

            scoredMoves.append((move, score))
            if score > bestScore { bestScore = score }
            alpha = max(alpha, bestScore)
        }

        // If the best score is a forced win/loss, don't randomise — play it
        // straight. Otherwise, pick uniformly at random from near-best moves.
        if abs(bestScore) >= Self.winScore {
            return scoredMoves.first(where: { $0.score == bestScore })?.move
        }

        let nearBest = scoredMoves.filter { bestScore - $0.score <= Self.moveTieMargin }
        return nearBest.randomElement()?.move ?? scoredMoves.first?.move
    }

    /// Recursive minimax with alpha-beta pruning.
    /// Positive scores favour the computer; negative scores favour the human.
    private func minimax(
        board: inout [Player?],
        depth: Int,
        alpha: Int,
        beta: Int,
        maximizing: Bool
    ) -> Int {
        // Terminal checks. Faster wins / slower losses are preferred via the depth bonus.
        if winningLine(for: Self.computerPlayer, on: board) != nil {
            return Self.winScore + depth
        }
        if winningLine(for: Self.humanPlayer, on: board) != nil {
            return -Self.winScore - depth
        }

        let empties = board.indices.filter { board[$0] == nil }
        if empties.isEmpty || depth == 0 {
            return staticEvaluation(of: board)
        }

        let moves = candidateMoves(on: board)
        var alpha = alpha
        var beta = beta

        if maximizing {
            var best = Int.min
            for move in moves {
                board[move] = Self.computerPlayer
                let score = minimax(board: &board, depth: depth - 1, alpha: alpha, beta: beta, maximizing: false)
                board[move] = nil
                if score > best { best = score }
                if best > alpha { alpha = best }
                if alpha >= beta { break }
            }
            return best
        } else {
            var best = Int.max
            for move in moves {
                board[move] = Self.humanPlayer
                let score = minimax(board: &board, depth: depth - 1, alpha: alpha, beta: beta, maximizing: true)
                board[move] = nil
                if score < best { best = score }
                if best < beta { beta = best }
                if alpha >= beta { break }
            }
            return best
        }
    }

    /// Restricts the branching factor by only considering empty cells within
    /// one square (Chebyshev distance) of an occupied cell. Falls back to all
    /// empties if the board is empty.
    private func candidateMoves(on boardState: [Player?]) -> [Int] {
        let empties = boardState.indices.filter { boardState[$0] == nil }
        guard boardState.contains(where: { $0 != nil }) else { return empties }

        var result: [Int] = []
        result.reserveCapacity(empties.count)

        for index in empties {
            let row = index / Self.boardSide
            let column = index % Self.boardSide
            var hasNeighbour = false

            outer: for rowOffset in -1...1 {
                for columnOffset in -1...1 where rowOffset != 0 || columnOffset != 0 {
                    let nearbyRow = row + rowOffset
                    let nearbyColumn = column + columnOffset
                    guard (0..<Self.boardSide).contains(nearbyRow),
                          (0..<Self.boardSide).contains(nearbyColumn) else { continue }
                    if boardState[self.index(row: nearbyRow, column: nearbyColumn)] != nil {
                        hasNeighbour = true
                        break outer
                    }
                }
            }

            if hasNeighbour { result.append(index) }
        }

        return result.isEmpty ? empties : result
    }

    /// Static evaluation: scans every 4-in-a-row window and scores it based on
    /// how many of each player's marks it contains.
    private func staticEvaluation(of boardState: [Player?]) -> Int {
        let directions = [(row: 0, column: 1), (row: 1, column: 0), (row: 1, column: 1), (row: 1, column: -1)]
        var score = 0

        for row in 0..<Self.boardSide {
            for column in 0..<Self.boardSide {
                for direction in directions {
                    let endRow = row + direction.row * (Self.winLength - 1)
                    let endColumn = column + direction.column * (Self.winLength - 1)
                    guard (0..<Self.boardSide).contains(endRow),
                          (0..<Self.boardSide).contains(endColumn) else { continue }

                    var computerCount = 0
                    var humanCount = 0
                    for offset in 0..<Self.winLength {
                        let cellRow = row + direction.row * offset
                        let cellColumn = column + direction.column * offset
                        switch boardState[index(row: cellRow, column: cellColumn)] {
                        case Self.computerPlayer?: computerCount += 1
                        case Self.humanPlayer?: humanCount += 1
                        default: break
                        }
                    }

                    if computerCount > 0 && humanCount > 0 { continue }
                    if computerCount > 0 {
                        score += windowWeight(for: computerCount)
                    } else if humanCount > 0 {
                        // Defensive bias: weight opponent threats slightly higher
                        // so the search prefers blocking over speculative attacks.
                        score -= windowWeight(for: humanCount) * 5 / 4
                    }
                }
            }
        }

        return score
    }

    private func windowWeight(for markCount: Int) -> Int {
        switch markCount {
        case 1: return 1
        case 2: return 12
        case 3: return 150
        case 4: return 100_000
        default: return 0
        }
    }

    private var availableMoves: [Int] {
        board.indices.filter { board[$0] == nil }
    }

    private func firstWinningMove(for player: Player, in moves: [Int]) -> Int? {
        for move in moves {
            var simulatedBoard = board
            simulatedBoard[move] = player

            if winningLine(for: player, on: simulatedBoard) != nil {
                return move
            }
        }

        return nil
    }

    private func scoreComputerMove(_ move: Int) -> Int {
        var computerBoard = board
        computerBoard[move] = Self.computerPlayer

        var humanBoard = board
        humanBoard[move] = Self.humanPlayer

        let row = move / Self.boardSide
        let column = move % Self.boardSide
        let center = Self.boardSide / 2
        let centerDistance = abs(row - center) + abs(column - center)
        let centerScore = max(0, 4 - centerDistance) * 8

        return centerScore
            + linePotentialScore(for: Self.computerPlayer, at: move, on: computerBoard) * 3
            + linePotentialScore(for: Self.humanPlayer, at: move, on: humanBoard) * 2
            + adjacentScore(around: move, on: computerBoard)
    }

    private func linePotentialScore(for player: Player, at move: Int, on boardState: [Player?]) -> Int {
        let directions = [(row: 0, column: 1), (row: 1, column: 0), (row: 1, column: 1), (row: 1, column: -1)]
        var score = 0

        for row in 0..<Self.boardSide {
            for column in 0..<Self.boardSide {
                for direction in directions {
                    let endRow = row + direction.row * (Self.winLength - 1)
                    let endColumn = column + direction.column * (Self.winLength - 1)

                    guard (0..<Self.boardSide).contains(endRow), (0..<Self.boardSide).contains(endColumn) else {
                        continue
                    }

                    let cells = (0..<Self.winLength).map { offset in
                        index(row: row + direction.row * offset, column: column + direction.column * offset)
                    }

                    guard cells.contains(move) else { continue }

                    let playerMarks = cells.filter { boardState[$0] == player }.count
                    let opponentMarks = cells.filter { boardState[$0] == player.opponent }.count

                    if opponentMarks == 0 {
                        score += potentialValue(for: playerMarks)
                    }
                }
            }
        }

        return score
    }

    private func potentialValue(for markCount: Int) -> Int {
        switch markCount {
        case 4: return 10_000
        case 3: return 220
        case 2: return 42
        case 1: return 8
        default: return 0
        }
    }

    private func adjacentScore(around move: Int, on boardState: [Player?]) -> Int {
        let row = move / Self.boardSide
        let column = move % Self.boardSide
        var score = 0

        for rowOffset in -1...1 {
            for columnOffset in -1...1 where rowOffset != 0 || columnOffset != 0 {
                let nearbyRow = row + rowOffset
                let nearbyColumn = column + columnOffset

                guard (0..<Self.boardSide).contains(nearbyRow), (0..<Self.boardSide).contains(nearbyColumn) else {
                    continue
                }

                if boardState[index(row: nearbyRow, column: nearbyColumn)] == Self.computerPlayer {
                    score += 6
                }
            }
        }

        return score
    }

    private func winningLine(for player: Player) -> [Int]? {
        winningLine(for: player, on: board)
    }

    private func winningLine(for player: Player, on boardState: [Player?]) -> [Int]? {
        let directions = [(row: 0, column: 1), (row: 1, column: 0), (row: 1, column: 1), (row: 1, column: -1)]

        for row in 0..<Self.boardSide {
            for column in 0..<Self.boardSide {
                for direction in directions {
                    let endRow = row + direction.row * (Self.winLength - 1)
                    let endColumn = column + direction.column * (Self.winLength - 1)

                    guard (0..<Self.boardSide).contains(endRow), (0..<Self.boardSide).contains(endColumn) else {
                        continue
                    }

                    let cells = (0..<Self.winLength).map { offset in
                        index(row: row + direction.row * offset, column: column + direction.column * offset)
                    }

                    if cells.allSatisfy({ boardState[$0] == player }) {
                        return cells
                    }
                }
            }
        }

        return nil
    }

    private func index(row: Int, column: Int) -> Int {
        row * Self.boardSide + column
    }

    private func cellFill(for player: Player?, isWinningCell: Bool) -> some ShapeStyle {
        if isWinningCell {
            return AnyShapeStyle(LinearGradient(colors: [.yellow.opacity(0.95), .orange.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }

        if let player {
            return AnyShapeStyle(player.backgroundColor)
        }

        return AnyShapeStyle(.white.opacity(0.13))
    }

    private func cellStroke(for player: Player?, isWinningCell: Bool) -> Color {
        if isWinningCell { return .white.opacity(0.95) }
        return player?.markColor.opacity(0.65) ?? .white.opacity(0.18)
    }

    private func cellShadow(for player: Player?, isWinningCell: Bool) -> Color {
        if isWinningCell { return .yellow.opacity(0.38) }
        return player?.markColor.opacity(0.24) ?? .black.opacity(0.18)
    }

    private func accessibilityLabel(for index: Int) -> String {
        let row = index / Self.boardSide + 1
        let column = index % Self.boardSide + 1

        if let player = board[index] {
            return "Row \(row), column \(column), occupied by \(player.rawValue)"
        }

        return "Row \(row), column \(column), empty"
    }
}

private enum Player: String {
    case x = "X"
    case o = "O"

    var opponent: Player {
        self == .x ? .o : .x
    }

    var markColor: Color {
        switch self {
        case .x:
            return .cyan
        case .o:
            return .pink
        }
    }

    var backgroundColor: Color {
        switch self {
        case .x:
            return .cyan.opacity(0.18)
        case .o:
            return .pink.opacity(0.18)
        }
    }
}

#Preview {
    ContentView()
}
