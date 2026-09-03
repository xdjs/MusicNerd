import Foundation

enum MusicIdentityError: LocalizedError, Equatable, Sendable {
  case missingArtistMetadata
  case noMatch
  case ambiguousMatch
  case belowConfidenceThreshold(score: Double)
  case offline
  case timedOut
  case serviceUnavailable

  var errorDescription: String? {
    switch self {
    case .missingArtistMetadata:
      return "The current item does not include an artist name."
    case .noMatch:
      return "Music Nerd could not identify the current artist."
    case .ambiguousMatch:
      return "Music Nerd found more than one possible artist."
    case .belowConfidenceThreshold:
      return "Music Nerd could not identify the current artist confidently enough."
    case .offline:
      return "Music Nerd is offline."
    case .timedOut:
      return "Artist identification timed out."
    case .serviceUnavailable:
      return "Artist identification is unavailable."
    }
  }
}
