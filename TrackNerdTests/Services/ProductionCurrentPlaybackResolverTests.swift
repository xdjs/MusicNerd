import XCTest
@testable import MusicNerd

@MainActor
final class ProductionCurrentPlaybackResolverTests: XCTestCase {
  func testAuthorizationFailureShortCircuitsBeforeReadingPlaybackSource() async {
    let unauthorizedStatuses: [PlaybackAuthorizationStatus] = [
      .notDetermined,
      .denied,
      .restricted,
      .unknown
    ]

    for status in unauthorizedStatuses {
      let sourceReader = PlaybackSourceReaderSpy(sourceItem: .unavailable)
      let resolver = MusicKitCurrentPlaybackResolver(
        authorizationProvider: AuthorizationProviderStub(status: status),
        sourceReader: sourceReader
      )

      do {
        _ = try await resolver.currentItem()
        XCTFail("Expected authorization failure for \(status)")
      } catch {
        XCTAssertEqual(
          error as? CurrentPlaybackError,
          .authorizationRequired(status)
        )
      }

      XCTAssertEqual(sourceReader.readCount, 0)
    }
  }

  func testAuthorizedWithoutCurrentEntryThrowsNothingPlaying() async {
    let sourceReader = PlaybackSourceReaderSpy(sourceItem: nil)
    let resolver = MusicKitCurrentPlaybackResolver(
      authorizationProvider: AuthorizationProviderStub(status: .authorized),
      sourceReader: sourceReader
    )

    do {
      _ = try await resolver.currentItem()
      XCTFail("Expected nothingPlaying")
    } catch {
      XCTAssertEqual(error as? CurrentPlaybackError, .nothingPlaying)
    }

    XCTAssertEqual(sourceReader.readCount, 1)
  }

  func testAuthorizedSongSourceMapsIntoProductionPlaybackItem() async throws {
    let sourceReader = PlaybackSourceReaderSpy(
      sourceItem: .song(
        sourceItemID: " song-123 ",
        title: " Test Song ",
        artistName: " Test Artist ",
        albumTitle: " Test Album "
      )
    )
    let resolver = MusicKitCurrentPlaybackResolver(
      authorizationProvider: AuthorizationProviderStub(status: .authorized),
      sourceReader: sourceReader
    )

    let item = try await resolver.currentItem()

    XCTAssertEqual(
      item,
      CurrentPlaybackItem(
        sourceItemID: "song-123",
        title: "Test Song",
        artistName: "Test Artist",
        albumTitle: "Test Album",
        kind: .song
      )
    )
    XCTAssertEqual(sourceReader.readCount, 1)
  }

  func testAuthorizedMusicVideoSourceMapsIntoProductionPlaybackItem() async throws {
    let sourceReader = PlaybackSourceReaderSpy(
      sourceItem: .musicVideo(
        sourceItemID: "video-123",
        title: "Test Video",
        artistName: "Test Artist",
        albumTitle: "Video Album"
      )
    )
    let resolver = MusicKitCurrentPlaybackResolver(
      authorizationProvider: AuthorizationProviderStub(status: .authorized),
      sourceReader: sourceReader
    )

    let item = try await resolver.currentItem()

    XCTAssertEqual(
      item,
      CurrentPlaybackItem(
        sourceItemID: "video-123",
        title: "Test Video",
        artistName: "Test Artist",
        albumTitle: "Video Album",
        kind: .musicVideo
      )
    )
    XCTAssertEqual(sourceReader.readCount, 1)
  }
}

@MainActor
private struct AuthorizationProviderStub: MusicAuthorizationProviding {
  let status: PlaybackAuthorizationStatus

  var currentStatus: PlaybackAuthorizationStatus {
    status
  }

  func requestAuthorization() async -> PlaybackAuthorizationStatus {
    status
  }
}

@MainActor
private final class PlaybackSourceReaderSpy: CurrentPlaybackSourceReading {
  private let sourceItem: CurrentPlaybackSourceItem?
  private(set) var readCount = 0

  init(sourceItem: CurrentPlaybackSourceItem?) {
    self.sourceItem = sourceItem
  }

  func currentSourceItem() -> CurrentPlaybackSourceItem? {
    readCount += 1
    return sourceItem
  }
}
