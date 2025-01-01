import XCTest
@testable import ChessCore

final class ChessTests: XCTestCase {
 func testFirstMoves() throws {
    for move in ["a3", "a4", "b3", "b4", "c3", "c4", "d3", "d4", "e3", "e4", "f3", "f4", "g3", "g4", "h3", "h4"] {
      var game = Game()
      try game.move(notation: move)
      print(game)
    }

    for move in ["Na3", "Nc3", "Nf3", "Nh3"] {
      var game = Game()
      try game.move(notation: move)
      print(game)
    }
  }

  func testScholarsMate() throws {
    var game = Game()
    try game.move(notation: "e4")
    try game.move(notation: "e5")
    try game.move(notation: "Qh5")
    try game.move(notation: "Nc6")
    try game.move(notation: "Bc4")
    try game.move(notation: "Nf6")
    try game.move(notation: "Qxf7#")
    print(game)
  }

  func testStalemate() throws {
    var game = Game(board: .init(pieces: [
      .init(notation: "e5")!: .init(color: .white, figure: .king),
      .init(notation: "e8")!: .init(color: .black, figure: .king),
      .init(notation: "e7")!: .init(color: .white, figure: .pawn)
    ]))
    try game.move(notation: "Ke6")
    print(game)
    XCTAssertTrue(game.isGameOver)
  }
}
