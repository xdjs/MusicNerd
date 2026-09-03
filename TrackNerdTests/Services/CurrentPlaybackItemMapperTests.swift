import XCTest
@testable import MusicNerd

final class CurrentPlaybackItemMapperTests: XCTestCase {
  private let mapper = CurrentPlaybackItemMapper()

  func testSongMapsIdentityAndMetadata() throws {
    let item = try mapper.map(
      .song(
        sourceItemID: " song-1 ",
        title: " Test Song ",
        artistName: " Test Artist ",
        albumTitle: " Test Album "
      )
    )

    XCTAssertEqual(item.sourceItemID, "song-1")
    XCTAssertEqual(item.title, "Test Song")
    XCTAssertEqual(item.artistName, "Test Artist")
    XCTAssertEqual(item.albumTitle, "Test Album")
    XCTAssertEqual(item.kind, .song)
  }

  func testMusicVideoPreservesAlbumMetadata() throws {
    let item = try mapper.map(
      .musicVideo(
        sourceItemID: "video-1",
        title: "Test Video",
        artistName: "Test Artist",
        albumTitle: "Video Album"
      )
    )

    XCTAssertEqual(item.sourceItemID, "video-1")
    XCTAssertEqual(item.albumTitle, "Video Album")
    XCTAssertEqual(item.kind, .musicVideo)
  }

  func testEmptyOptionalMetadataBecomesNil() throws {
    let item = try mapper.map(
      .song(
        sourceItemID: "song-1",
        title: "Test Song",
        artistName: "   ",
        albumTitle: nil
      )
    )

    XCTAssertNil(item.artistName)
    XCTAssertNil(item.albumTitle)
  }

  func testUnavailableSourceThrowsItemUnavailable() {
    XCTAssertThrowsError(try mapper.map(.unavailable)) { error in
      XCTAssertEqual(error as? CurrentPlaybackError, .itemUnavailable)
    }
  }

  func testUnsupportedSourceThrowsUnsupportedItem() {
    XCTAssertThrowsError(try mapper.map(.unsupported)) { error in
      XCTAssertEqual(error as? CurrentPlaybackError, .unsupportedItem)
    }
  }

  func testBlankRequiredMetadataThrowsInsufficientMetadata() {
    XCTAssertThrowsError(
      try mapper.map(
        .song(
          sourceItemID: "song-1",
          title: "  ",
          artistName: "Test Artist",
          albumTitle: nil
        )
      )
    ) { error in
      XCTAssertEqual(error as? CurrentPlaybackError, .insufficientMetadata)
    }
  }
}
