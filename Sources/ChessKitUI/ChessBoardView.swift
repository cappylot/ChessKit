//
//  ChessBoardView.swift
//  ChessKitUI
//
//  Created by Codex on 2024-xx-xx.
//

#if canImport(SwiftUI)
import SwiftUI
import ChessKit

/// SwiftUI chess board backed by `ChessKit` move generation.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct ChessBoardView: View {
    
    @ObservedObject private var viewModel: ChessBoardViewModel
    @State private var dragState: DragState?
    
    /// Creates a new board with an optional custom view model.
    public init(viewModel: ChessBoardViewModel = ChessBoardViewModel()) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let squareSize = boardSize / 8
            
            ZStack(alignment: .topLeading) {
                self.boardGrid(squareSize: squareSize)
                
                if let dragState = self.dragState,
                   let piece = self.viewModel.piece(at: dragState.from) {
                    self.pieceView(for: piece)
                        .frame(width: squareSize, height: squareSize)
                        .position(dragState.location)
                        .shadow(radius: 6)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: boardSize, height: boardSize)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .gesture(self.dragGesture(squareSize: squareSize))
        }
    }
    
    private func boardGrid(squareSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach((0..<8).reversed(), id: \.self) { rank in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { file in
                        let square = Square(file: file, rank: rank)
                        self.squareView(square: square, squareSize: squareSize)
                    }
                }
            }
        }
    }
    
    private func squareView(square: Square, squareSize: CGFloat) -> some View {
        let isDark = (square.file + square.rank) % 2 == 1
        let highlightTargets = Set(self.viewModel.highlightedMoves.map { $0.to })
        let isHighlighted = highlightTargets.contains(square)
        let isSelected = self.viewModel.selectedSquare == square
        let draggedFromHere = self.dragState?.from == square
        
        return ZStack {
            Rectangle()
                .fill(isDark ? Color(red: 0.46, green: 0.36, blue: 0.28) : Color(red: 0.94, green: 0.89, blue: 0.82))
            
            if isHighlighted {
                Circle()
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: squareSize * 0.45, height: squareSize * 0.45)
            }
            
            if isSelected {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 3)
            }
            
            if let piece = self.viewModel.piece(at: square) {
                self.pieceView(for: piece)
                    .opacity(draggedFromHere ? 0 : 1)
            }
        }
        .frame(width: squareSize, height: squareSize)
        .onTapGesture {
            if let selected = self.viewModel.selectedSquare, selected != square {
                if !self.viewModel.move(from: selected, to: square) {
                    self.viewModel.select(square: square)
                }
            } else if self.viewModel.selectedSquare == square {
                self.viewModel.clearSelection()
            } else {
                self.viewModel.select(square: square)
            }
        }
    }
    
    private func pieceView(for piece: Piece) -> some View {
        let imageName = self.imageName(for: piece)
        // By default this looks in the consuming app's asset catalog so users can provide their own SVGs.
        return Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    private func imageName(for piece: Piece) -> String {
        let prefix = piece.color == .white ? "w" : "b"
        let suffix: String
        switch piece.kind {
        case .pawn: suffix = "p"
        case .knight: suffix = "n"
        case .bishop: suffix = "b"
        case .rook: suffix = "r"
        case .queen: suffix = "q"
        case .king: suffix = "k"
        }
        return "\(prefix)\(suffix)"
    }
    
    private func dragGesture(squareSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let startSquare = self.square(at: value.startLocation, squareSize: squareSize) else {
                    self.dragState = nil
                    return
                }
                
                if self.dragState == nil {
                    self.viewModel.select(square: startSquare)
                    self.dragState = DragState(from: startSquare, location: value.location)
                } else {
                    self.dragState?.location = value.location
                }
            }
            .onEnded { value in
                guard let start = self.dragState?.from ?? self.square(at: value.startLocation, squareSize: squareSize),
                      let end = self.square(at: value.location, squareSize: squareSize) else {
                    self.dragState = nil
                    return
                }
                
                if !self.viewModel.move(from: start, to: end) {
                    self.viewModel.select(square: end)
                }
                self.dragState = nil
            }
    }
    
    private func square(at location: CGPoint, squareSize: CGFloat) -> Square? {
        let file = Int(location.x / squareSize)
        let rankFromTop = Int(location.y / squareSize)
        let rank = 7 - rankFromTop
        
        guard (0..<8).contains(file), (0..<8).contains(rank) else {
            return nil
        }
        return Square(file: file, rank: rank)
    }
}

private struct DragState {
    let from: Square
    var location: CGPoint
}

#endif
