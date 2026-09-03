import Foundation

struct StaticMusicIdentityCrosswalk: MusicIdentityCrosswalkProviding {
  private let entriesBySourceIdentity: [String: MusicIdentityCrosswalkEntry]

  init(entries: [MusicIdentityCrosswalkEntry] = []) {
    self.entriesBySourceIdentity = Dictionary(
      entries.map { ($0.sourceStableIdentity, $0) },
      uniquingKeysWith: { _, latest in latest }
    )
  }

  func entry(
    for playbackItem: CurrentPlaybackItem
  ) async -> MusicIdentityCrosswalkEntry? {
    entriesBySourceIdentity[playbackItem.stableIdentity]
  }
}
