//
//  Game.swift
//  chess
//
//  Created by Ilias Karim on 7/15/21.
//  Copyright © 2021 Ilias Karim. All rights reserved.
//

import Foundation

fileprivate extension Square {
  enum InvalidNotation: Error {
    case incorrectLength(length: Int)
    case invalidFileName(name: String)
    case invalidRankIndex(index: String)
  }

  init(notation: String) throws {
    guard notation.count == 2 else {
      throw InvalidNotation.incorrectLength(length: notation.count)
    }

    let fileName = String(notation[notation.startIndex..<notation.index(notation.startIndex, offsetBy: 1)])
    guard let file = File(rawValue: fileName) else {
      throw InvalidNotation.invalidFileName(name: fileName)
    }

    let rankIndexString = notation[notation.index(notation.startIndex, offsetBy: 1)..<notation.endIndex]
    guard let rankIndex = Int(rankIndexString), let rank = Rank(rawValue: rankIndex) else {
      throw InvalidNotation.invalidRankIndex(index: String(rankIndexString))
    }

    self.init(file: file, rank: rank)
  }
}

public struct Game {
  public typealias Board = [Square: Piece]

  struct InvalidMove: Error {
    let notation: String
  }

  enum Outcome {
    case checkmate(victor: Piece.Color)
    case drawnGame(isStalemate: Bool)
    case resignedGame(victor: Piece.Color)
  }

  public var victor: Piece.Color? {
    guard let outcome = outcome else { return nil }
    switch outcome {
    case let .checkmate(victor):
      return victor
    case let .resignedGame(victor):
      return victor
    default: return nil
    }
  }

  private var board: Board
  private var enPassantCapture: Square?
  private var isBlackKingMoved = false
  private var isWhiteKingMoved = false
  private var isNorthEastRookMoved = false
  private var isNorthWestRookMoved = false
  private var isSouthEastRookMoved = false
  private var isSouthWestRookMoved = false
  private var nextMoveColor: Piece.Color {
    moves.count.isMultiple(of: 2) ? .white : .black
  }
  private var moves = [String]()
  private var outcome: Outcome?

  public mutating func move(_ notation: String) throws {
    let notation = notation.filter { $0 != "+" && $0 != "#" } // TO DO: validate + / #
    guard notation.count > 0 else { return }

    switch (notation, nextMoveColor) {
    case ("1-0", .black):
      moves += [notation]
      outcome = .resignedGame(victor: .white)
      return

    case ("0-1", .white):
      moves += [notation]
      outcome = .resignedGame(victor: .black)
      return

    case ("1/2-1/2", _):
      moves += [notation]
      outcome = .drawnGame(isStalemate: false)
      return

    case ("O-O", .black):
      guard !board.isCheck(color: .black), !isBlackKingMoved, !isNorthEastRookMoved, board[.f8] == nil, board[.g8] == nil else {
        throw InvalidMove(notation: notation)
      }

      var mutableBoard = board
      mutableBoard[.f8] = mutableBoard.removeValue(forKey: .e8)
      guard !mutableBoard.isCheck(color: .black) else { break }

      mutableBoard[.g8] = mutableBoard.removeValue(forKey: .f8)
      guard !mutableBoard.isCheck(color: .black) else { break }

      moves += [notation]
      board = mutableBoard
      board[.f8] = board.removeValue(forKey: .h8)
      return

    case ("O-O", .white):
      guard !board.isCheck(color: .white), !isWhiteKingMoved, !isSouthEastRookMoved, board[.f1] == nil, board[.g1] == nil else {
        throw InvalidMove(notation: notation)
      }

      var mutableBoard = board
      mutableBoard[.f1] = mutableBoard.removeValue(forKey: .e1)
      guard !mutableBoard.isCheck(color: .white) else { break }

      mutableBoard[.g1] = mutableBoard.removeValue(forKey: .f1)
      guard !mutableBoard.isCheck(color: .white) else { break }

      moves += [notation]
      board = mutableBoard
      board[.f1] = board.removeValue(forKey: .h1)
      return

    case ("O-O-O", .black):
      guard !board.isCheck(color: .black), !isBlackKingMoved, !isNorthWestRookMoved, board[.c8] == nil, board[.d8] == nil else {
        throw InvalidMove(notation: notation)
      }

      var mutableBoard = board
      mutableBoard[.d8] = mutableBoard.removeValue(forKey: .e8)
      guard !mutableBoard.isCheck(color: .black) else { return }

      mutableBoard[.c8] = mutableBoard.removeValue(forKey: .d8)
      guard !mutableBoard.isCheck(color: .black) else { return }

      moves += [notation]
      board = mutableBoard
      board[.d8] = board.removeValue(forKey: .a8)
      return

    case ("O-O-O", .white):
      guard !board.isCheck(color: .white), !isWhiteKingMoved, !isSouthWestRookMoved, board[.c1] == nil, board[.d1] == nil else {
        throw InvalidMove(notation: notation)
      }

      var mutableBoard = board
      mutableBoard[.d1] = mutableBoard.removeValue(forKey: .e1)
      guard !mutableBoard.isCheck(color: .white) else { return }

      mutableBoard[.c1] = mutableBoard.removeValue(forKey: .d1)
      guard !mutableBoard.isCheck(color: .white) else { return }

      moves += [notation]
      board = mutableBoard
      board[.d1] = board.removeValue(forKey: .a1)
      return // to do: assess outcome of game

    default:
      let isCapture = notation.contains("x")
      let filteredNotation = notation.filter { !["x", "+", "#"].contains($0) }

      let figureNotation = filteredNotation[filteredNotation.startIndex..<filteredNotation.index(after: filteredNotation.startIndex)]
      let piece: Piece
      var destinationNotation: Substring
      if let figure = Piece.Figure(rawValue: String(figureNotation)) {
        destinationNotation = filteredNotation[filteredNotation.index(after: filteredNotation.startIndex)..<filteredNotation.endIndex]
        piece = Piece(color: nextMoveColor, figure: figure)
      } else {
        if isCapture {
          destinationNotation = filteredNotation[filteredNotation.index(after: filteredNotation.startIndex)..<filteredNotation.endIndex]
        } else {
          destinationNotation = filteredNotation[filteredNotation.startIndex..<filteredNotation.endIndex]
        }
        piece = Piece(color: nextMoveColor, figure: .pawn)
      }

      let promotedPiece: Piece?
      if let pieceNotation = destinationNotation.last, pieceNotation.isUppercase {
        guard let figure = Piece.Figure(rawValue: String(pieceNotation)), figure != .king, figure != .pawn else {
          throw InvalidMove(notation: notation)
        }
        promotedPiece = Piece(color: nextMoveColor, figure: figure)
        destinationNotation = destinationNotation.dropLast()
      } else {
        promotedPiece = nil
      }

      let disambiguationFile: Square.File?
      let disambiguationRank: Square.Rank?
      if destinationNotation.count == 4 {
        guard let rankInt = Int(String(destinationNotation.first!)), let rank = Square.Rank(rawValue: rankInt) else {
          throw InvalidMove(notation: notation)
        }
        disambiguationRank = rank

        destinationNotation = destinationNotation.dropFirst()

        guard let file = Square.File(rawValue: String(destinationNotation.first!)) else {
          throw InvalidMove(notation: notation)
        }
        disambiguationFile = file

        destinationNotation = destinationNotation.dropFirst()
      } else if destinationNotation.count == 3 && Square.File.allCases.map(\.rawValue).contains(String(destinationNotation.first!)) {

        disambiguationFile = Square.File(rawValue: String(destinationNotation.first!))!
        disambiguationRank = nil

        destinationNotation = destinationNotation.dropFirst()
      } else if destinationNotation.count == 3 {
        guard let rankInt = Int(String(destinationNotation.first!)), let rank = Square.Rank(rawValue: rankInt) else {
          throw InvalidMove(notation: notation)
        }

        disambiguationFile = nil
        disambiguationRank = rank
      } else {
        disambiguationFile = nil
        disambiguationRank = nil
      }

      let destination = try Square(notation: String(destinationNotation))

      let isEnPassantCapture: Bool
      if isCapture {
        switch nextMoveColor {
        case .white:
          if piece.figure == .pawn &&
            destination.file == enPassantCapture?.file &&
            destination.rank - 1 == enPassantCapture?.rank {
            isEnPassantCapture = true
          } else {
            guard board[destination] != nil else {
              throw InvalidMove(notation: notation)
            }
            isEnPassantCapture = false
          }
        case .black:
          if piece.figure == .pawn &&
            destination.file == enPassantCapture?.file &&
            destination.rank + 1 == enPassantCapture?.rank {
            isEnPassantCapture = true
          } else {
            guard board[destination] != nil else {
              throw InvalidMove(notation: notation)
            }
            isEnPassantCapture = false
          }
        }
      } else {
        isEnPassantCapture = false
      }

      // Find eligible piece(s).
      let pieces = board.filter { square, squarePiece in
        guard squarePiece == piece else { return false }

        let destinationSquares = isCapture ? board.capturesFromSquare(square) : board.movesFromSquare(square)
        guard destinationSquares.contains(destination) else { return false }

        if let disambiguationFile = disambiguationFile, square.file != disambiguationFile { return false }
        if let disambiguationRank = disambiguationRank, square.rank != disambiguationRank { return false }

        return true
      }

      guard let origin = pieces.first?.key, pieces.count == 1 else {
        throw InvalidMove(notation: notation)
      }

      var mutableBoard = board

      // Move piece.
      if let promotedPiece = promotedPiece {
        mutableBoard[origin] = nil
        mutableBoard[destination] = promotedPiece
      } else {
        mutableBoard[destination] = mutableBoard.removeValue(forKey: origin)
      }

      // Account for en passant captures.
      if isEnPassantCapture {
        mutableBoard[enPassantCapture!] = nil
      }

      // Do not allow moving into check.
      if mutableBoard.isCheck(color: nextMoveColor) {
        throw InvalidMove(notation: notation)
      }

      board = mutableBoard

      if piece.figure == .pawn && abs(origin.rank - destination.rank) == 2 {
        enPassantCapture = destination
      } else {
        enPassantCapture = nil
      }

      if origin.file == .a && origin.rank == .one {
        isSouthWestRookMoved = true
      } else if origin.file == .a && origin.rank == .eight {
        isNorthWestRookMoved = true
      } else if origin.file == .h && origin.rank == .one {
        isSouthEastRookMoved = true
      } else if origin.file == .h && origin.rank == .eight {
        isNorthEastRookMoved = true
      } else if origin.file == .e {
        if origin.rank == .one {
          isWhiteKingMoved = true
        } else if origin.rank == .eight {
          isBlackKingMoved = true
        }
      }
    }

    if board.isCheck(color: nextMoveColor.opposite) {
      if board.isCheckmate(color: nextMoveColor.opposite) {
        outcome = .checkmate(victor: nextMoveColor)
        moves += [notation + "#"]
      } else {
        moves += [notation + "+"]
      }
    } else {
      moves += [notation]
    }
  }

  /// Designated initializer
  public init(board: Board = .defaultGameBoard) {
    self.board = board
  }
}

extension Game: CustomStringConvertible {
  public var description: String {
    let boardDescription = Square.Rank.allCases.reversed().map { rank in
      " ".appending(String(rank.rawValue).appending(" ").appending(
        Square.File.allCases.map { file in
          if let piece = board[Square(file: file, rank: rank)] {
            return piece.color == .white ? piece.figure.rawValue : piece.figure.rawValue.lowercased()
          } else {
            return " "
          }
        }.joined(separator: " ")
      ))
    }.joined(separator: "\n").appending("\n   ").appending(
      Square.File.allCases.map { file in
        file.rawValue
      }.joined(separator: " ")
    )

    let state: String
    switch outcome {
    case let .checkmate(victor):
      state = "\(victor.rawValue.capitalized) wins."
    case .drawnGame(_):
      state = "Drawn game"
    case let .resignedGame(victor):
      state = "\(victor.rawValue.capitalized) wins."
    case .none:
      switch nextMoveColor {
      case .black:
        state = "Black to move"
      case .white:
        state = "White to move"
      }
    }

    return (!moves.isEmpty ? stride(from: 0, to: moves.count, by: 2).map { i in
      "\(i/2+1). "
        .appending(moves[i])
        .appending(moves.count > i+1 ? " \(moves[i+1])" : "")
      }.joined(separator: "\n")
    .appending("\n\n") : "")
    .appending("  \(state.description)\n\n")
    .appending(boardDescription)
    }
}

public extension Game.Board {
  static var defaultGameBoard: Game.Board {
    let allPieces: [Piece] = Piece.Color.allCases.flatMap { color in
      Piece.Figure.allCases.map { figure in
        Piece(color: color, figure: figure)
      }
    }
    return allPieces.reduce(into: Game.Board()) { result, piece in
      piece.startingSquares.forEach { square in
        result[square] = piece
      }
    }
  }
}

fileprivate extension Game.Board {
  func capturesFromSquare(_ square: Square) -> [Square] {
    guard let piece = self[square] else { return [] }
    return piece.capturesFromSquare(square).map { sequence -> [Square] in
      guard let firstObstructedIndex = sequence.firstIndex(where: { move in
        self[move] != nil
      }) else {
        return sequence
      }
      return [Square](sequence[sequence.startIndex...firstObstructedIndex])
    }.flatMap { $0 }.filter { move in
      self[move]?.color != piece.color
    }
  }

  func isCheck(color: Piece.Color) -> Bool {
    guard let kingsSquare = first(where: { _, piece in
      piece == Piece(color: color, figure: .king)
    })?.key else { return false }

    return filter { $0.value.color == color.opposite }.contains { square in
      capturesFromSquare(square.key).contains(kingsSquare)
    }
  }

  func isCheckmate(color: Piece.Color) -> Bool {
    !contains { square, piece in
      piece.color == color && movesFromSquare(square).contains { move in
        var board = self
        let piece = board[square]
        board[square] = nil
        board[move] = piece
        return !board.isCheck(color: color)
      }
    }
  }

  func movesFromSquare(_ square: Square) -> [Square] {
    guard let piece = self[square] else { return [] }
    return piece.movesFromSquare(square).map { sequence -> [Square] in
      guard let firstObstructedIndex = sequence.firstIndex(where: { move in
        self[move] != nil
      }) else {
        return sequence
      }
      return [Square](sequence[sequence.startIndex..<firstObstructedIndex])
    }.flatMap { $0 }
  }
}

