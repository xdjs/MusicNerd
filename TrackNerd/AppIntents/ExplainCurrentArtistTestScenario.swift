#if DEBUG
import Foundation

enum ExplainCurrentArtistTestScenario: String, CaseIterable, Sendable {
  case success
  case authorizationDenied
  case noPlayback
  case unsupportedContent
  case ambiguousIdentity
  case offline
  case noKnowledge

  @MainActor
  func result(scope: KnowledgeScope) throws -> KnowledgeAnswer {
    switch self {
    case .success:
      let playbackItem = CurrentPlaybackItem(
        sourceItemID: "app-intents-test-song",
        title: "Test Song",
        artistName: "Test Artist",
        albumTitle: "Test Album",
        kind: .song
      )
      let identity = MusicIdentity(
        playbackItem: playbackItem,
        musicNerdSongID: nil,
        musicNerdArtistID: "app-intents-test-artist",
        canonicalArtistName: "Test Artist",
        resolutionMethod: .normalizedArtistName,
        confidence: 1
      )
      return KnowledgeAnswer(
        scope: scope,
        identity: identity,
        spokenText: "Test Artist is a Music Nerd test artist.",
        source: .musicNerdAPI
      )
    case .authorizationDenied:
      throw CurrentPlaybackError.authorizationRequired(.denied)
    case .noPlayback:
      throw CurrentPlaybackError.nothingPlaying
    case .unsupportedContent:
      throw CurrentPlaybackError.unsupportedItem
    case .ambiguousIdentity:
      throw MusicIdentityError.ambiguousMatch
    case .offline:
      throw MusicKnowledgeError.offline
    case .noKnowledge:
      throw MusicKnowledgeError.noData
    }
  }
}
#endif
