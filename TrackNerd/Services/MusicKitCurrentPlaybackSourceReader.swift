import MusicKit

@MainActor
protocol CurrentPlaybackSourceReading: Sendable {
  func currentSourceItem() -> CurrentPlaybackSourceItem?
}

@MainActor
struct MusicKitCurrentPlaybackSourceReader: CurrentPlaybackSourceReading {
  func currentSourceItem() -> CurrentPlaybackSourceItem? {
    guard let entry = SystemMusicPlayer.shared.queue.currentEntry else {
      return nil
    }
    return Self.sourceItem(from: entry)
  }

  static func sourceItem(
    from entry: MusicPlayer.Queue.Entry
  ) -> CurrentPlaybackSourceItem {
    switch entry.item {
    case .song(let song):
      return .song(
        sourceItemID: song.id.rawValue,
        title: song.title,
        artistName: song.artistName,
        albumTitle: song.albumTitle
      )
    case .musicVideo(let video):
      return .musicVideo(
        sourceItemID: video.id.rawValue,
        title: video.title,
        artistName: video.artistName,
        albumTitle: video.albumTitle
      )
    case nil:
      return .unavailable
    @unknown default:
      return .unsupported
    }
  }
}
