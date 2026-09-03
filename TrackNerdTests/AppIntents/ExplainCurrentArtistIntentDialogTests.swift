import XCTest
@testable import MusicNerd

final class ExplainCurrentArtistIntentDialogTests: XCTestCase {
  func testMapsEveryPlaybackFailure() {
    assertMessage(
      "Open Music Nerd and allow Apple Music access first.",
      for: CurrentPlaybackError.authorizationRequired(.notDetermined)
    )
    assertMessage(
      "Allow Apple Music access for Music Nerd in Settings.",
      for: CurrentPlaybackError.authorizationRequired(.denied)
    )
    assertMessage(
      "Apple Music access is restricted on this device.",
      for: CurrentPlaybackError.authorizationRequired(.restricted)
    )
    assertMessage(
      "Apple Music access changed. Try again.",
      for: CurrentPlaybackError.authorizationRequired(.authorized)
    )
    assertMessage(
      "Apple Music access is unavailable right now.",
      for: CurrentPlaybackError.authorizationRequired(.unknown)
    )
    assertMessage(
      "Play something in Apple Music, then try again.",
      for: CurrentPlaybackError.nothingPlaying
    )
    assertMessage(
      "I can't read the current Apple Music item. Try another song.",
      for: CurrentPlaybackError.itemUnavailable
    )
    assertMessage(
      "That type of Apple Music item isn't supported yet.",
      for: CurrentPlaybackError.unsupportedItem
    )
    assertMessage(
      "The current item doesn't have enough artist information.",
      for: CurrentPlaybackError.insufficientMetadata
    )
  }

  func testMapsEveryIdentityFailure() {
    assertMessage(
      "The current item doesn't have enough artist information.",
      for: MusicIdentityError.missingArtistMetadata
    )
    assertMessage(
      "Music Nerd doesn't have a confident match for this artist.",
      for: MusicIdentityError.noMatch
    )
    assertMessage(
      "Music Nerd found multiple possible artists and won't guess.",
      for: MusicIdentityError.ambiguousMatch
    )
    assertMessage(
      "Music Nerd doesn't have a confident match for this artist.",
      for: MusicIdentityError.belowConfidenceThreshold(score: 0.2)
    )
    assertMessage(
      "Music Nerd is offline. Reconnect and try again.",
      for: MusicIdentityError.offline
    )
    assertMessage(
      "Music Nerd took too long to identify the artist. Try again.",
      for: MusicIdentityError.timedOut
    )
    assertMessage(
      "Music Nerd's artist service is unavailable right now.",
      for: MusicIdentityError.serviceUnavailable
    )
  }

  func testMapsEveryKnowledgeFailure() {
    assertMessage(
      "Music Nerd doesn't have a confident match for this artist.",
      for: MusicKnowledgeError.missingArtistIdentity
    )
    assertMessage(
      "Music Nerd can't explain this artist yet.",
      for: MusicKnowledgeError.songKnowledgeUnavailable
    )
    assertMessage(
      "Music Nerd doesn't have a confident match for this artist.",
      for: MusicKnowledgeError.lowConfidence
    )
    assertMessage(
      "Music Nerd doesn't have artist details yet.",
      for: MusicKnowledgeError.noData
    )
    assertMessage(
      "Music Nerd is offline. Reconnect and try again.",
      for: MusicKnowledgeError.offline
    )
    assertMessage(
      "Music Nerd took too long to answer. Try again.",
      for: MusicKnowledgeError.timedOut
    )
    assertMessage(
      "Music Nerd's artist service is unavailable right now.",
      for: MusicKnowledgeError.serviceUnavailable
    )
  }

  func testMapsCancellationAndRedactsUnexpectedErrors() {
    assertMessage("Okay, I stopped.", for: CancellationError())
    assertMessage(
      "Music Nerd couldn't answer right now. Try again.",
      for: DialogSecretError()
    )
  }

  private func assertMessage(
    _ expectedMessage: String,
    for error: any Error,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      ExplainCurrentArtistIntentDialog.message(for: error),
      expectedMessage,
      file: file,
      line: line
    )
  }
}

private struct DialogSecretError: LocalizedError {
  var errorDescription: String? { "secret transport response" }
}
