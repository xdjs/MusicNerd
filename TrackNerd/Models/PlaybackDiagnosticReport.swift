#if DEBUG
import Foundation

enum PlaybackDiagnosticStatus: String, Equatable, Sendable {
  case stopped
  case playing
  case paused
  case interrupted
  case seekingForward
  case seekingBackward
  case unknown

  var displayName: String {
    switch self {
    case .stopped:
      return "Stopped"
    case .playing:
      return "Playing"
    case .paused:
      return "Paused"
    case .interrupted:
      return "Interrupted"
    case .seekingForward:
      return "Seeking Forward"
    case .seekingBackward:
      return "Seeking Backward"
    case .unknown:
      return "Unknown"
    }
  }

  var isSeeking: Bool {
    self == .seekingForward || self == .seekingBackward
  }
}

struct PlaybackDiagnosticSnapshot: Equatable, Sendable {
  let capturedAt: Date
  let capturedAtUptime: TimeInterval
  let queueEntryID: String?
  let entryTitle: String?
  let entrySubtitle: String?
  let isTransient: Bool
  let transientItemID: String?
  let transientItemType: String?
  let item: CurrentPlaybackItem?
  let playbackStatus: PlaybackDiagnosticStatus
  let playbackTime: TimeInterval
}

enum PlaybackDiagnosticResolution: Equatable, Sendable {
  case resolved(CurrentPlaybackItem)
  case failed(CurrentPlaybackError)
  case unexpectedFailure(String)
}

enum PlaybackDifference: Equatable, Sendable {
  case itemIdentityChanged
  case playbackStatusChanged(PlaybackDiagnosticStatus, PlaybackDiagnosticStatus)
  case transientStateChanged
  case transientItemChanged
  case positionMovedBackward(TimeInterval)
  case positionAdvancedTooFar(actual: TimeInterval, maximumExpected: TimeInterval)

  var description: String {
    switch self {
    case .itemIdentityChanged:
      return "The item identity changed while the queue entry stayed the same."
    case .playbackStatusChanged(let before, let after):
      return "Playback status changed from \(before.displayName) to \(after.displayName)."
    case .transientStateChanged:
      return "The queue entry's transient state changed."
    case .transientItemChanged:
      return "The transient item identity or type changed."
    case .positionMovedBackward(let amount):
      return "Playback moved backward by \(Self.seconds(amount))."
    case .positionAdvancedTooFar(let actual, let maximumExpected):
      return "Playback advanced \(Self.seconds(actual)); at most \(Self.seconds(maximumExpected)) was expected."
    }
  }

  private static func seconds(_ value: TimeInterval) -> String {
    String(format: "%.3f seconds", value)
  }
}

enum PlaybackComparisonResult: Equatable, Sendable {
  case noUnexpectedChange
  case possibleMutation([PlaybackDifference])
  case inconclusive(String)
}

struct PlaybackDiagnosticReport: Equatable, Sendable {
  let before: PlaybackDiagnosticSnapshot
  let resolution: PlaybackDiagnosticResolution
  let after: PlaybackDiagnosticSnapshot
  let comparison: PlaybackComparisonResult

  init(
    before: PlaybackDiagnosticSnapshot,
    resolution: PlaybackDiagnosticResolution,
    after: PlaybackDiagnosticSnapshot,
    comparator: PlaybackSnapshotComparator = PlaybackSnapshotComparator()
  ) {
    self.before = before
    self.resolution = resolution
    self.after = after
    self.comparison = comparator.compare(before: before, after: after)
  }
}
#endif
