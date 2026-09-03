import Foundation

enum MusicKnowledgeError: LocalizedError, Equatable, Sendable {
  case missingArtistIdentity
  case songKnowledgeUnavailable
  case lowConfidence
  case noData
  case offline
  case timedOut
  case serviceUnavailable

  var errorDescription: String? {
    switch self {
    case .missingArtistIdentity:
      return "The current artist has not been identified."
    case .songKnowledgeUnavailable:
      return "Song-specific explanations are not available yet."
    case .lowConfidence:
      return "Music Nerd is not confident enough to answer."
    case .noData:
      return "Music Nerd does not have an explanation for this artist yet."
    case .offline:
      return "Music Nerd cannot reach its knowledge service right now."
    case .timedOut:
      return "The Music Nerd knowledge request timed out."
    case .serviceUnavailable:
      return "The Music Nerd knowledge service is unavailable."
    }
  }
}
