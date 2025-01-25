
/// A model representing an error due to some invalid notation.
public enum InvalidNotation: Error {
  case ambiguous(candidates: [String])
  case badPunctuation(correctPunctuation: String)
  case illegalMove
  case unparseable
}
