#if DEBUG
import Foundation
import MusicKit

@MainActor
protocol PlaybackSnapshotReading: Sendable {
  func snapshot() -> PlaybackDiagnosticSnapshot
}

@MainActor
struct MusicKitPlaybackSnapshotReader: PlaybackSnapshotReading {
  func snapshot() -> PlaybackDiagnosticSnapshot {
    let player = SystemMusicPlayer.shared
    let entry = player.queue.currentEntry
    let transientItem = entry?.transientItem
    let mappedItem = entry.flatMap { try? MusicKitCurrentPlaybackResolver.item(from: $0) }
    let playbackStatus = Self.map(player.state.playbackStatus)
    let playbackTime = player.playbackTime
    let capturedAtUptime = ProcessInfo.processInfo.systemUptime
    let capturedAt = Date()

    return PlaybackDiagnosticSnapshot(
      capturedAt: capturedAt,
      capturedAtUptime: capturedAtUptime,
      queueEntryID: entry?.id,
      entryTitle: entry?.title,
      entrySubtitle: entry?.subtitle,
      isTransient: entry?.isTransient ?? false,
      transientItemID: transientItem?.id.rawValue,
      transientItemType: transientItem.map { String(reflecting: Swift.type(of: $0)) },
      item: mappedItem,
      playbackStatus: playbackStatus,
      playbackTime: playbackTime
    )
  }

  private static func map(_ status: MusicPlayer.PlaybackStatus) -> PlaybackDiagnosticStatus {
    switch status {
    case .stopped:
      return .stopped
    case .playing:
      return .playing
    case .paused:
      return .paused
    case .interrupted:
      return .interrupted
    case .seekingForward:
      return .seekingForward
    case .seekingBackward:
      return .seekingBackward
    @unknown default:
      return .unknown
    }
  }
}
#endif
