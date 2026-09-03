import Foundation

protocol MusicIdentityCrosswalkProviding: Sendable {
  func entry(
    for playbackItem: CurrentPlaybackItem
  ) async -> MusicIdentityCrosswalkEntry?
}
