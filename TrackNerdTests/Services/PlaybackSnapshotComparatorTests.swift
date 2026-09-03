#if DEBUG
import XCTest
@testable import MusicNerd

final class PlaybackSnapshotComparatorTests: XCTestCase {
  private let item = CurrentPlaybackItem(
    sourceItemID: "12345",
    title: "Test Song",
    artistName: "Test Artist",
    albumTitle: "Test Album",
    kind: .song
  )

  func testPlayingWithNormalProgressHasNoUnexpectedChange() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .playing)
    let after = snapshot(uptime: 100.2, playbackTime: 42.2, status: .playing)

    XCTAssertEqual(compare(before, after), .noUnexpectedChange)
  }

  func testPausedWithStablePositionHasNoUnexpectedChange() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .paused)
    let after = snapshot(uptime: 100.2, playbackTime: 42.1, status: .paused)

    XCTAssertEqual(compare(before, after), .noUnexpectedChange)
  }

  func testExcessiveForwardJumpReportsPossibleMutation() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .playing)
    let after = snapshot(uptime: 100.1, playbackTime: 50, status: .playing)

    guard case .possibleMutation(let differences) = compare(before, after) else {
      return XCTFail("Expected a possible mutation result")
    }

    XCTAssertEqual(differences.count, 1)
    guard case .positionAdvancedTooFar = differences[0] else {
      return XCTFail("Expected an excessive forward-position difference")
    }
  }

  func testBackwardJumpReportsPossibleMutation() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .playing)
    let after = snapshot(uptime: 100.1, playbackTime: 30, status: .playing)

    guard case .possibleMutation(let differences) = compare(before, after) else {
      return XCTFail("Expected a possible mutation result")
    }

    XCTAssertEqual(differences, [.positionMovedBackward(12)])
  }

  func testStatusChangeReportsPossibleMutation() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .playing)
    let after = snapshot(uptime: 100.1, playbackTime: 42.1, status: .paused)

    XCTAssertEqual(
      compare(before, after),
      .possibleMutation([.playbackStatusChanged(.playing, .paused)])
    )
  }

  func testItemIdentityChangeReportsPossibleMutation() {
    let otherItem = CurrentPlaybackItem(
      sourceItemID: "67890",
      title: "Another Song",
      artistName: "Test Artist",
      albumTitle: nil,
      kind: .song
    )
    let before = snapshot(uptime: 100, playbackTime: 42, status: .paused)
    let after = snapshot(
      uptime: 100.1,
      playbackTime: 42,
      status: .paused,
      item: otherItem
    )

    XCTAssertEqual(compare(before, after), .possibleMutation([.itemIdentityChanged]))
  }

  func testTransientChangeReportsPossibleMutation() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .paused)
    let after = snapshot(
      uptime: 100.1,
      playbackTime: 42,
      status: .paused,
      isTransient: true,
      transientItemID: "transient-1",
      transientItemType: "MusicKit.Song"
    )

    XCTAssertEqual(
      compare(before, after),
      .possibleMutation([.transientStateChanged, .transientItemChanged])
    )
  }

  func testQueueEntryChangeIsInconclusive() {
    let before = snapshot(uptime: 100, playbackTime: 199.9, status: .playing)
    let after = snapshot(
      uptime: 100.2,
      playbackTime: 0.1,
      status: .playing,
      queueEntryID: "entry-2"
    )

    guard case .inconclusive(let reason) = compare(before, after) else {
      return XCTFail("Expected an inconclusive result")
    }

    XCTAssertTrue(reason.contains("natural track transition"))
  }

  func testSeekingBaselineIsInconclusive() {
    let before = snapshot(uptime: 100, playbackTime: 42, status: .seekingForward)
    let after = snapshot(uptime: 100.1, playbackTime: 45, status: .seekingForward)

    guard case .inconclusive = compare(before, after) else {
      return XCTFail("Expected an inconclusive result")
    }
  }

  func testResolutionFailureStillComparesSnapshots() {
    let before = snapshot(
      uptime: 100,
      playbackTime: 42,
      status: .paused,
      includeMappedItem: false
    )
    let after = snapshot(
      uptime: 100.1,
      playbackTime: 42,
      status: .paused,
      includeMappedItem: false
    )
    let report = PlaybackDiagnosticReport(
      before: before,
      resolution: .failed(.itemUnavailable),
      after: after
    )

    XCTAssertEqual(report.comparison, .noUnexpectedChange)
  }

  private func compare(
    _ before: PlaybackDiagnosticSnapshot,
    _ after: PlaybackDiagnosticSnapshot
  ) -> PlaybackComparisonResult {
    PlaybackSnapshotComparator(positionTolerance: 0.5)
      .compare(before: before, after: after)
  }

  private func snapshot(
    uptime: TimeInterval,
    playbackTime: TimeInterval,
    status: PlaybackDiagnosticStatus,
    queueEntryID: String = "entry-1",
    item: CurrentPlaybackItem? = nil,
    isTransient: Bool = false,
    transientItemID: String? = nil,
    transientItemType: String? = nil,
    includeMappedItem: Bool = true
  ) -> PlaybackDiagnosticSnapshot {
    PlaybackDiagnosticSnapshot(
      capturedAt: Date(timeIntervalSince1970: uptime),
      capturedAtUptime: uptime,
      queueEntryID: queueEntryID,
      entryTitle: item?.title ?? self.item.title,
      entrySubtitle: item?.artistName ?? self.item.artistName,
      isTransient: isTransient,
      transientItemID: transientItemID,
      transientItemType: transientItemType,
      item: includeMappedItem ? (item ?? self.item) : nil,
      playbackStatus: status,
      playbackTime: playbackTime
    )
  }
}
#endif
