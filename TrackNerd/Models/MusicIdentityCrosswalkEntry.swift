import Foundation

struct MusicIdentityCrosswalkEntry: Equatable, Sendable {
  let sourceItemID: String
  let sourceKind: CurrentPlaybackItem.Kind
  let musicNerdSongID: String?
  let musicNerdArtistID: String?
  let canonicalArtistName: String?

  var sourceStableIdentity: String {
    "\(sourceKind.rawValue):\(sourceItemID)"
  }
}
