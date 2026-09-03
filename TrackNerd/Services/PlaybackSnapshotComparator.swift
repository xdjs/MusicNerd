#if DEBUG
import Foundation

struct PlaybackSnapshotComparator: Sendable {
  let positionTolerance: TimeInterval

  init(positionTolerance: TimeInterval = 0.75) {
    self.positionTolerance = positionTolerance
  }

  func compare(
    before: PlaybackDiagnosticSnapshot,
    after: PlaybackDiagnosticSnapshot
  ) -> PlaybackComparisonResult {
    guard after.capturedAtUptime >= before.capturedAtUptime else {
      return .inconclusive("The monotonic capture clock moved backward; repeat the diagnostic.")
    }

    guard before.queueEntryID == after.queueEntryID else {
      return .inconclusive(
        "The current queue entry changed during capture. This may be a natural track transition; repeat the diagnostic."
      )
    }

    var differences: [PlaybackDifference] = []

    if before.playbackStatus != after.playbackStatus {
      differences.append(
        .playbackStatusChanged(before.playbackStatus, after.playbackStatus)
      )
    }

    if before.item?.stableIdentity != after.item?.stableIdentity {
      differences.append(.itemIdentityChanged)
    }

    if before.isTransient != after.isTransient {
      differences.append(.transientStateChanged)
    }

    if before.transientItemID != after.transientItemID ||
        before.transientItemType != after.transientItemType {
      differences.append(.transientItemChanged)
    }

    if !differences.isEmpty {
      return .possibleMutation(differences)
    }

    if before.playbackStatus.isSeeking {
      return .inconclusive("Playback was already seeking when capture began; repeat after seeking stops.")
    }

    if before.playbackStatus == .unknown {
      return .inconclusive("Playback reported an unknown status; repeat on a supported state.")
    }

    let elapsed = after.capturedAtUptime - before.capturedAtUptime
    let positionDelta = after.playbackTime - before.playbackTime

    switch before.playbackStatus {
    case .playing:
      if positionDelta < -positionTolerance {
        differences.append(.positionMovedBackward(abs(positionDelta)))
      } else if positionDelta > elapsed + positionTolerance {
        differences.append(
          .positionAdvancedTooFar(
            actual: positionDelta,
            maximumExpected: elapsed + positionTolerance
          )
        )
      }
    case .stopped, .paused, .interrupted:
      if positionDelta < -positionTolerance {
        differences.append(.positionMovedBackward(abs(positionDelta)))
      } else if positionDelta > positionTolerance {
        differences.append(
          .positionAdvancedTooFar(
            actual: positionDelta,
            maximumExpected: positionTolerance
          )
        )
      }
    case .seekingForward, .seekingBackward, .unknown:
      break
    }

    if differences.isEmpty {
      return .noUnexpectedChange
    }

    return .possibleMutation(differences)
  }
}
#endif
