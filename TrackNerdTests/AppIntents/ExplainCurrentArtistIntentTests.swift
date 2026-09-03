import XCTest
@testable import MusicNerd

@MainActor
final class ExplainCurrentArtistIntentTests: XCTestCase {
  func testPerformReturnsGroundedAnswerAsValueAndRequestsArtistScope() async throws {
    let coordinator = IntentCoordinatorStub(
      result: .success(makeAnswer(text: "Grounded artist answer."))
    )
    let intent = makeIntent(coordinator: coordinator)

    let result = try await intent.perform()

    XCTAssertEqual(result.value, "Grounded artist answer.")
    XCTAssertEqual(coordinator.receivedScopes, [.artist])
  }

  func testPerformReturnsMappedFailureAsValue() async throws {
    let coordinator = IntentCoordinatorStub(
      result: .failure(MusicIdentityError.ambiguousMatch)
    )
    let intent = makeIntent(coordinator: coordinator)

    let result = try await intent.perform()

    XCTAssertEqual(
      result.value,
      "Music Nerd found multiple possible artists and won't guess."
    )
    XCTAssertEqual(coordinator.receivedScopes, [.artist])
  }

  func testPerformDoesNotExposeUnexpectedErrorText() async throws {
    let coordinator = IntentCoordinatorStub(
      result: .failure(IntentSecretError())
    )
    let intent = makeIntent(coordinator: coordinator)

    let result = try await intent.perform()

    XCTAssertEqual(
      result.value,
      "Music Nerd couldn't answer right now. Try again."
    )
    XCTAssertFalse(result.value?.contains("private backend detail") == true)
  }

  #if DEBUG
  func testDebugScenarioNamesAreStableForOutOfProcessTests() {
    XCTAssertEqual(
      Set(ExplainCurrentArtistTestScenario.allCases.map(\.rawValue)),
      Set([
        "success",
        "authorizationDenied",
        "noPlayback",
        "unsupportedContent",
        "ambiguousIdentity",
        "offline",
        "noKnowledge"
      ])
    )
  }

  func testDebugCoordinatorOverrideCanBeResetToProduction() async throws {
    let productionAnswer = makeAnswer(text: "Production answer.")
    let productionCoordinator = IntentCoordinatorStub(
      result: .success(productionAnswer)
    )
    let coordinator = MusicNerdAppIntentCoordinator(
      productionCoordinator: productionCoordinator
    )

    coordinator.configureTestScenario(.success)
    let testAnswer = try await coordinator.overview(scope: .artist)
    coordinator.resetTestScenario()
    let restoredAnswer = try await coordinator.overview(scope: .artist)

    XCTAssertEqual(
      testAnswer.spokenText,
      "Test Artist is a Music Nerd test artist."
    )
    XCTAssertEqual(restoredAnswer, productionAnswer)
    XCTAssertEqual(productionCoordinator.receivedScopes, [.artist])
  }
  #endif

  private func makeIntent(
    coordinator: any CurrentMusicQuestionCoordinating
  ) -> ExplainCurrentArtistIntent {
    ExplainCurrentArtistIntent(testCoordinator: coordinator)
  }

  private func makeAnswer(text: String) -> KnowledgeAnswer {
    let item = CurrentPlaybackItem(
      sourceItemID: "song-1",
      title: "Song One",
      artistName: "Artist One",
      albumTitle: "Album One",
      kind: .song
    )
    let identity = MusicIdentity(
      playbackItem: item,
      musicNerdSongID: nil,
      musicNerdArtistID: "artist-1",
      canonicalArtistName: "Artist One",
      resolutionMethod: .normalizedArtistName,
      confidence: 1
    )
    return KnowledgeAnswer(
      scope: .artist,
      identity: identity,
      spokenText: text,
      source: .musicNerdAPI
    )
  }
}

@MainActor
private final class IntentCoordinatorStub: CurrentMusicQuestionCoordinating {
  private let result: Swift.Result<KnowledgeAnswer, any Error>
  private(set) var receivedScopes: [KnowledgeScope] = []

  init(result: Swift.Result<KnowledgeAnswer, any Error>) {
    self.result = result
  }

  func overview(scope: KnowledgeScope) async throws -> KnowledgeAnswer {
    receivedScopes.append(scope)
    return try result.get()
  }
}

private struct IntentSecretError: LocalizedError {
  var errorDescription: String? { "private backend detail" }
}
