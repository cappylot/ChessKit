//
//  ChessBoardViewModel.swift
//  ChessKitUI
//
//  Created by Codex on 2024-xx-xx.
//

#if canImport(SwiftUI)
import Foundation
import ChessKit

/// Observable wrapper around `Game` that exposes state for SwiftUI views.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class ChessBoardViewModel: ObservableObject {
    
    /// Published snapshot of the current position.
    @Published public private(set) var position: Position
    
    /// Selected square, if any.
    @Published public private(set) var selectedSquare: Square?
    
    /// Legal moves for `selectedSquare`.
    @Published public private(set) var highlightedMoves: [Move] = []
    
    /// Default promotion piece when multiple promotion moves are available.
    public var defaultPromotion: PieceKind = .queen
    
    /// Underlying game engine.
    public private(set) var game: Game
    
    private let rules = StandardRules()
    
    /// Initializes the game view model.
    /// - Parameter startingFen: Start position FEN. Defaults to the standard initial chess position.
    public init(startingFen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") {
        let startPosition = FenSerialization.default.deserialize(fen: startingFen)
        self.game = Game(position: startPosition)
        self.position = startPosition
    }
    
    /// Returns the piece at a given square.
    public func piece(at square: Square) -> Piece? {
        self.game.position.board[square]
    }
    
    /// Current player's turn.
    public var turn: PieceColor {
        self.game.position.state.turn
    }
    
    /// Highlights legal moves for the piece on a given square.
    public func select(square: Square?) {
        guard let square = square,
              let piece = self.game.position.board[square],
              piece.color == self.turn else {
            self.clearSelection()
            return
        }
        
        self.selectedSquare = square
        self.highlightedMoves = self.rules.movesForPiece(at: square, in: self.game.position)
    }
    
    /// Applies a move if it is legal.
    @discardableResult
    public func move(from: Square, to: Square) -> Bool {
        guard let move = self.resolvedMove(from: from, to: to) else {
            return false
        }
        
        self.game.make(move: move)
        self.position = self.game.position
        self.clearSelection()
        return true
    }
    
    /// Clears current selection and highlights.
    public func clearSelection() {
        self.selectedSquare = nil
        self.highlightedMoves = []
    }
    
    private func resolvedMove(from: Square, to: Square) -> Move? {
        let candidates = self.rules
            .movesForPiece(at: from, in: self.game.position)
            .filter { $0.to == to }
        
        guard !candidates.isEmpty else {
            return nil
        }
        
        if candidates.count == 1 {
            return candidates.first
        }
        
        if let preferred = candidates.first(where: { $0.promotion == self.defaultPromotion }) {
            return preferred
        }
        
        return candidates.first
    }
}

#endif
