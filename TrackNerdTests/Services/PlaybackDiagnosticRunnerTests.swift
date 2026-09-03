#if DEBUG
import XCTest
@testable import MusicNerd

@MainActor
final class PlaybackDiagnosticRunnerTests: XCTestCase {
  func testCaptureReadsBeforeThenResolvesThenAlwaysReadsAfter() async throws {
    let recorder = PlaybackDiagnosticCallRecorder()
    let before = makeSnapshot(uptime: 100)
    let after = makeSnapshot(uptime: 100.1)
    let snapshotReader = MockPlaybackSnapshotReader(
      snapshots: [before, after],
      recorder: recorder
    )
    let resolver = MockCurrentPlaybackResolver(
      result: .failure(.itemUnavailable),
      recorder: recorder
    )
    let runner = MusicKitPlaybackDiagnosticRunner(
      resolver: resolver,
      authorizationProvider: MockMusicAuthorizationProvider(status: .authorized),
      snapshotReader: snapshotReader
    )

    let report = try await runner.capture()

    XCTAssertEqual(recorder.calls, ["snapshot", "resolve", "snapshot"])
    XCTAssertEqual(report.before, before)
    XCTAssertEqual(report.after, after)
    XCTAssertEqual(
      report.resolution,
      PlaybackDiagnosticResolution.failed(.itemUnavailable)
    )
  }

  func testCaptureReturnsResolvedItem() async throws {
    let item = CurrentPlaybackItem(
      sourceItemID: "song-1",
      title: "Test Song",
      artistName: "Test Artist",
      albumTitle: nil,
      kind: .song
    )
    let snapshot = makeSnapshot(uptime: 100, item: item)
    let runner = MusicKitPlaybackDiagnosticRunner(
      resolver: MockCurrentPlaybackResolver(result: .success(item)),
      authorizationProvider: MockMusicAuthorizationProvider(status: .authorized),
      snapshotReader: MockPlaybackSnapshotReader(snapshots: [snapshot, snapshot])
    )

    let report = try await runner.capture()

    XCTAssertEqual(
      report.resolution,
      PlaybackDiagnosticResolution.resolved(item)
    )
  }

  func testCaptureWithoutAuthorizationDoesNotReadPlayback() async {
    let recorder = PlaybackDiagnosticCallRecorder()
    let runner = MusicKitPlaybackDiagnosticRunner(
      resolver: MockCurrentPlaybackResolver(
        result: .failure(.nothingPlaying),
        recorder: recorder
      ),
      authorizationProvider: MockMusicAuthorizationProvider(status: .denied),
      snapshotReader: MockPlaybackSnapshotReader(
        snapshots: [makeSnapshot(uptime: 100)],
        recorder: recorder
      )
    )

    do {
      _ = try await runner.capture()
      XCTFail("Expected authorizationRequired")
    } catch {
      XCTAssertEqual(
        error as? CurrentPlaybackError,
        .authorizationRequired(.denied)
      )
    }

    XCTAssertTrue(recorder.calls.isEmpty)
  }

  private func makeSnapshot(
    uptime: TimeInterval,
    item: CurrentPlaybackItem? = nil
  ) -> PlaybackDiagnosticSnapshot {
    PlaybackDiagnosticSnapshot(
      capturedAt: Date(timeIntervalSince1970: uptime),
      capturedAtUptime: uptime,
      queueEntryID: "entry-1",
      entryTitle: item?.title,
      entrySubtitle: item?.artistName,
      isTransient: false,
      transientItemID: nil,
      transientItemType: nil,
      item: item,
      playbackStatus: .paused,
      playbackTime: 42
    )
  }
}

@MainActor
private final class PlaybackDiagnosticCallRecorder {
  var calls: [String] = []
}

@MainActor
private final class MockMusicAuthorizationProvider: MusicAuthorizationProviding {
  var status: PlaybackAuthorizationStatus

  init(status: PlaybackAuthorizationStatus) {
    self.status = status
  }

  var currentStatus: PlaybackAuthorizationStatus {
    status
  }

  func requestAuthorization() async -> PlaybackAuthorizationStatus {
    status
  }
}

@MainActor
private final class MockCurrentPlaybackResolver: CurrentPlaybackResolving {
  let result: Swift.Result<CurrentPlaybackItem, CurrentPlaybackError>
  let recorder: PlaybackDiagnosticCallRecorder?

  init(
    result: Swift.Result<CurrentPlaybackItem, CurrentPlaybackError>,
    recorder: PlaybackDiagnosticCallRecorder? = nil
  ) {
    self.result = result
    self.recorder = recorder
  }

  func currentItem() async throws -> CurrentPlaybackItem {
    recorder?.calls.append("resolve")
    return try result.get()
  }
}

@MainActor
private final class MockPlaybackSnapshotReader: PlaybackSnapshotReading {
  private var snapshots: [PlaybackDiagnosticSnapshot]
  private let recorder: PlaybackDiagnosticCallRecorder?

  init(
    snapshots: [PlaybackDiagnosticSnapshot],
    recorder: PlaybackDiagnosticCallRecorder? = nil
  ) {
    self.snapshots = snapshots
    self.recorder = recorder
  }

  func snapshot() -> PlaybackDiagnosticSnapshot {
    recorder?.calls.append("snapshot")
    return snapshots.removeFirst()
  }
}
#endif
