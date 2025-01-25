
// MARK: - Square

/// A model representing a square on a chess board.
public struct Square: Hashable {
  /// A model representing the file of a board square.
  public enum File: Int, CaseIterable {
    case a = 1, b, c, d, e, f, g, h

    init?(_ character: Character) {
      guard let ascii = character.asciiValue else {
        return nil
      }
      self.init(rawValue: Int(ascii) - 96)
    }
  }

  /// A model representing the rank of a board square.
  public enum Rank: Int, CaseIterable {
    case one = 1, two, three, four, five, six, seven, eight

    init?(_ character: Character) {
      guard let int = Int(String(character)) else {
        return nil
      }
      self.init(rawValue: int)
    }
  }

  /// Square file.
  public let file: File

  /// Square rank.
  public let rank: Rank

  /// Designated initializer.
  /// - Parameters:
  ///   - file: Square file
  ///   - rank: Square rank
  public init(file: File, rank: Rank) {
    self.file = file
    self.rank = rank
  }

  /// Convenience initializer.
  /// - Parameter string: Square notation
  public init?(notation: String) {
    guard let file = notation.first.map(File.init) ?? nil,
          let rank = notation.last.map(Rank.init) ?? nil,
          notation.count == 2 else {
      return nil
    }
    self.init(file: file, rank: rank)
  }
}

extension Square {
  static func + (lhs: Self, rhs: Vector) -> Self? {
    guard let file = File(rawValue: lhs.file.rawValue + rhs.files),
          let rank = Rank(rawValue: lhs.rank.rawValue + rhs.ranks) else {
      return nil
    }
    return .init(file: file, rank: rank)
  }
}

extension Square: CustomStringConvertible {
  public var description: String {
    "\(file)\(rank)"
  }
}

extension Square.File: CustomStringConvertible {
  public var description: String {
    String(Character(UnicodeScalar(rawValue + 96)!))
  }
}

extension Square.Rank: CustomStringConvertible {
  public var description: String {
    String(rawValue)
  }
}
