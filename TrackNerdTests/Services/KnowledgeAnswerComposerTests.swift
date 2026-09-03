import XCTest
@testable import MusicNerd

final class KnowledgeAnswerComposerTests: XCTestCase {
  func testCompositionUsesOnlyGroundedRecordTextAndRemovesDuplicates() throws {
    let identity = makeIdentity()
    let composer = KnowledgeAnswerComposer(
      maximumSentenceCount: 4,
      maximumCharacterCount: 300
    )
    let record = ArtistKnowledgeRecord(
      artistID: "artist-1",
      artistName: "Test Artist",
      biography: "First grounded sentence. Second grounded sentence.",
      facts: [
        "Second grounded sentence.",
        "Third grounded sentence."
      ]
    )

    let answer = try composer.compose(record: record, identity: identity)

    XCTAssertEqual(
      answer.spokenText,
      "First grounded sentence. Second grounded sentence. Third grounded sentence."
    )
    XCTAssertEqual(answer.identity, identity)
    XCTAssertEqual(answer.scope, .artist)
    XCTAssertEqual(answer.source, .musicNerdAPI)
  }

  func testCompositionLimitsSentenceCount() throws {
    let composer = KnowledgeAnswerComposer(
      maximumSentenceCount: 2,
      maximumCharacterCount: 300
    )
    let record = ArtistKnowledgeRecord(
      artistID: "artist-1",
      artistName: "Test Artist",
      biography: "Sentence one. Sentence two. Sentence three.",
      facts: ["Sentence four."]
    )

    let answer = try composer.compose(
      record: record,
      identity: makeIdentity()
    )

    XCTAssertEqual(answer.spokenText, "Sentence one. Sentence two.")
  }

  func testLongFirstSentenceIsTruncatedAtWordBoundaryWithinLimit() throws {
    let maximumCharacterCount = 90
    let source = String(
      repeating: "grounded words remain attributable ",
      count: 8
    ) + "."
    let composer = KnowledgeAnswerComposer(
      maximumSentenceCount: 4,
      maximumCharacterCount: maximumCharacterCount
    )
    let record = ArtistKnowledgeRecord(
      artistID: "artist-1",
      artistName: "Test Artist",
      biography: source,
      facts: []
    )

    let answer = try composer.compose(
      record: record,
      identity: makeIdentity()
    )

    XCTAssertLessThanOrEqual(answer.spokenText.count, maximumCharacterCount)
    XCTAssertTrue(answer.spokenText.hasSuffix("…"))
    XCTAssertTrue(source.hasPrefix(String(answer.spokenText.dropLast())))
    XCTAssertFalse(answer.spokenText.dropLast().hasSuffix(" "))
  }

  func testEmptyGroundingThrowsNoData() {
    let composer = KnowledgeAnswerComposer()
    let record = ArtistKnowledgeRecord(
      artistID: "artist-1",
      artistName: "Test Artist",
      biography: "   ",
      facts: ["", "  "]
    )

    XCTAssertThrowsError(
      try composer.compose(record: record, identity: makeIdentity())
    ) { error in
      XCTAssertEqual(error as? MusicKnowledgeError, .noData)
    }
  }

  private func makeIdentity() -> MusicIdentity {
    MusicIdentity(
      playbackItem: CurrentPlaybackItem(
        sourceItemID: "song-1",
        title: "Test Song",
        artistName: "Test Artist",
        albumTitle: nil,
        kind: .song
      ),
      musicNerdSongID: nil,
      musicNerdArtistID: "artist-1",
      canonicalArtistName: "Test Artist",
      resolutionMethod: .normalizedArtistName,
      confidence: 1
    )
  }
}
