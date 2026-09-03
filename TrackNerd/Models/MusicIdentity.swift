import Foundation

struct MusicIdentity: Equatable, Sendable {
  enum ResolutionMethod: String, Equatable, Sendable {
    case appleMusicCrosswalk
    case normalizedArtistName
  }

  let playbackItem: CurrentPlaybackItem
  let musicNerdSongID: String?
  let musicNerdArtistID: String?
  let canonicalArtistName: String?
  let resolutionMethod: ResolutionMethod
  let confidence: Double
}
