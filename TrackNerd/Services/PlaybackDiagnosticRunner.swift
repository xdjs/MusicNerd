#if DEBUG
@MainActor
protocol PlaybackDiagnosticRunning: Sendable {
  func capture() async throws -> PlaybackDiagnosticReport
}

@MainActor
struct MusicKitPlaybackDiagnosticRunner: PlaybackDiagnosticRunning {
  private let resolver: any CurrentPlaybackResolving
  private let authorizationProvider: any MusicAuthorizationProviding
  private let snapshotReader: any PlaybackSnapshotReading
  private let comparator: PlaybackSnapshotComparator

  init(
    resolver: (any CurrentPlaybackResolving)? = nil,
    authorizationProvider: (any MusicAuthorizationProviding)? = nil,
    snapshotReader: (any PlaybackSnapshotReading)? = nil,
    comparator: PlaybackSnapshotComparator = PlaybackSnapshotComparator()
  ) {
    let authorizationProvider = authorizationProvider ?? MusicKitAuthorizationProvider()
    self.resolver = resolver ?? MusicKitCurrentPlaybackResolver(
      authorizationProvider: authorizationProvider
    )
    self.authorizationProvider = authorizationProvider
    self.snapshotReader = snapshotReader ?? MusicKitPlaybackSnapshotReader()
    self.comparator = comparator
  }

  func capture() async throws -> PlaybackDiagnosticReport {
    let authorizationStatus = authorizationProvider.currentStatus
    guard authorizationStatus == .authorized else {
      throw CurrentPlaybackError.authorizationRequired(authorizationStatus)
    }

    let before = snapshotReader.snapshot()
    let resolution: PlaybackDiagnosticResolution

    do {
      resolution = .resolved(try await resolver.currentItem())
    } catch let error as CurrentPlaybackError {
      resolution = .failed(error)
    } catch {
      resolution = .unexpectedFailure(error.localizedDescription)
    }

    let after = snapshotReader.snapshot()

    return PlaybackDiagnosticReport(
      before: before,
      resolution: resolution,
      after: after,
      comparator: comparator
    )
  }
}
#endif
