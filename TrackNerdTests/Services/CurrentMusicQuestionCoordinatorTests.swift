import XCTest
@testable import MusicNerd

@MainActor
final class CurrentMusicQuestionCoordinatorTests: XCTestCase {
  func testOverviewRunsPlaybackThenIdentityThenKnowledgeInStrictOrder() async throws {
    let recorder = CoordinatorCallRecorder()
    let item = makeItem(sourceItemID: "song-1", artistName: "Artist One")
    let identity = makeIdentity(item: item, artistID: "artist-1")
    let expectedAnswer = makeAnswer(identity: identity)
    let playbackResolver = SequencedPlaybackResolver(
      items: [item],
      recorder: recorder
    )
    let identityResolver = RecordingIdentityResolver(
      identitiesBySourceID: ["song-1": identity],
      recorder: recorder
    )
    let knowledgeService = RecordingKnowledgeService(
      answersByArtistID: ["artist-1": expectedAnswer],
      recorder: recorder
    )
    let coordinator = CurrentMusicQuestionCoordinator(
      playbackResolver: playbackResolver,
      identityResolver: identityResolver,
      knowledgeService: knowledgeService
    )

    let answer = try await coordinator.overview(scope: .artist)

    XCTAssertEqual(answer, expectedAnswer)
    XCTAssertEqual(recorder.calls, ["playback", "identity", "knowledge"])
    XCTAssertEqual(identityResolver.receivedItems, [item])
    XCTAssertEqual(knowledgeService.receivedScopes, [.artist])
    XCTAssertEqual(knowledgeService.receivedIdentities, [identity])
  }

  func testEachOverviewReadsFreshPlaybackBeforeResolvingAndAnswering() async throws {
    let recorder = CoordinatorCallRecorder()
    let firstItem = makeItem(sourceItemID: "song-1", artistName: "Artist One")
    let secondItem = makeItem(sourceItemID: "song-2", artistName: "Artist Two")
    let firstIdentity = makeIdentity(item: firstItem, artistID: "artist-1")
    let secondIdentity = makeIdentity(item: secondItem, artistID: "artist-2")
    let playbackResolver = SequencedPlaybackResolver(
      items: [firstItem, secondItem],
      recorder: recorder
    )
    let identityResolver = RecordingIdentityResolver(
      identitiesBySourceID: [
        "song-1": firstIdentity,
        "song-2": secondIdentity
      ],
      recorder: recorder
    )
    let knowledgeService = RecordingKnowledgeService(
      answersByArtistID: [
        "artist-1": makeAnswer(identity: firstIdentity, text: "First answer."),
        "artist-2": makeAnswer(identity: secondIdentity, text: "Second answer.")
      ],
      recorder: recorder
    )
    let coordinator = CurrentMusicQuestionCoordinator(
      playbackResolver: playbackResolver,
      identityResolver: identityResolver,
      knowledgeService: knowledgeService
    )

    let firstAnswer = try await coordinator.overview(scope: .artist)
    let secondAnswer = try await coordinator.overview(scope: .artist)

    XCTAssertEqual(firstAnswer.identity.playbackItem, firstItem)
    XCTAssertEqual(secondAnswer.identity.playbackItem, secondItem)
    XCTAssertEqual(playbackResolver.readCount, 2)
    XCTAssertEqual(identityResolver.receivedItems, [firstItem, secondItem])
    XCTAssertEqual(
      recorder.calls,
      [
        "playback", "identity", "knowledge",
        "playback", "identity", "knowledge"
      ]
    )
  }

  func testCancellationAfterPlaybackPreventsDownstreamWork() async {
    let recorder = CoordinatorCallRecorder()
    let item = makeItem(sourceItemID: "song-1", artistName: "Artist One")
    let identity = makeIdentity(item: item, artistID: "artist-1")
    let playbackResolver = SequencedPlaybackResolver(
      items: [item],
      recorder: recorder,
      cancelCurrentTaskAfterRead: true
    )
    let identityResolver = RecordingIdentityResolver(
      identitiesBySourceID: ["song-1": identity],
      recorder: recorder
    )
    let knowledgeService = RecordingKnowledgeService(
      answersByArtistID: ["artist-1": makeAnswer(identity: identity)],
      recorder: recorder
    )
    let coordinator = CurrentMusicQuestionCoordinator(
      playbackResolver: playbackResolver,
      identityResolver: identityResolver,
      knowledgeService: knowledgeService
    )

    do {
      _ = try await coordinator.overview(scope: .artist)
      XCTFail("Expected cancellation")
    } catch is CancellationError {
      // Expected.
    } catch {
      XCTFail("Expected CancellationError, got \(error)")
    }

    XCTAssertEqual(recorder.calls, ["playback"])
    XCTAssertTrue(identityResolver.receivedItems.isEmpty)
    XCTAssertTrue(knowledgeService.receivedIdentities.isEmpty)
  }

  func testExpiredIdentityEnablesStaleKnowledgeAnswerWhileOffline() async throws {
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(61)
    let item = makeItem(sourceItemID: "song-1", artistName: "Artist One")
    let staleIdentity = makeIdentity(item: item, artistID: "artist-1")
    let identityCache = ExpiringCache<String, MusicIdentity>()
    await identityCache.insert(
      staleIdentity,
      for: item.stableIdentity,
      timeToLive: 60,
      now: cachedAt
    )
    let artistLookup = OfflineCoordinatorArtistLookup()
    let identityResolver = MusicIdentityResolver(
      crosswalk: CoordinatorEmptyIdentityCrosswalk(),
      artistLookup: artistLookup,
      cache: identityCache,
      now: { now }
    )

    let knowledgeCache = ExpiringCache<String, KnowledgeAnswer>()
    await knowledgeCache.insert(
      makeAnswer(
        identity: staleIdentity,
        text: "Previously grounded offline answer."
      ),
      for: "artist:artist-1",
      timeToLive: 60,
      now: cachedAt
    )
    let knowledgeLoader = OfflineCoordinatorKnowledgeLoader()
    let knowledgeService = MusicKnowledgeService(
      artistLoader: knowledgeLoader,
      cache: knowledgeCache,
      cacheTimeToLive: 60,
      now: { now }
    )
    let coordinator = CurrentMusicQuestionCoordinator(
      playbackResolver: SequencedPlaybackResolver(
        items: [item],
        recorder: CoordinatorCallRecorder()
      ),
      identityResolver: identityResolver,
      knowledgeService: knowledgeService
    )

    let answer = try await coordinator.overview(scope: .artist)

    XCTAssertEqual(answer.source, .staleCache)
    XCTAssertEqual(answer.spokenText, "Previously grounded offline answer.")
    XCTAssertEqual(answer.identity.playbackItem, item)
    XCTAssertEqual(artistLookup.requestedNames, ["Artist One"])
    XCTAssertEqual(knowledgeLoader.requestedArtistIDs, ["artist-1"])
  }

  private func makeItem(
    sourceItemID: String,
    artistName: String
  ) -> CurrentPlaybackItem {
    CurrentPlaybackItem(
      sourceItemID: sourceItemID,
      title: "Song \(sourceItemID)",
      artistName: artistName,
      albumTitle: nil,
      kind: .song
    )
  }

  private func makeIdentity(
    item: CurrentPlaybackItem,
    artistID: String
  ) -> MusicIdentity {
    MusicIdentity(
      playbackItem: item,
      musicNerdSongID: nil,
      musicNerdArtistID: artistID,
      canonicalArtistName: item.artistName,
      resolutionMethod: .normalizedArtistName,
      confidence: 1
    )
  }

  private func makeAnswer(
    identity: MusicIdentity,
    text: String = "Grounded answer."
  ) -> KnowledgeAnswer {
    KnowledgeAnswer(
      scope: .artist,
      identity: identity,
      spokenText: text,
      source: .musicNerdAPI
    )
  }
}

@MainActor
private final class CoordinatorCallRecorder {
  var calls: [String] = []
}

@MainActor
private final class SequencedPlaybackResolver: CurrentPlaybackResolving {
  private var items: [CurrentPlaybackItem]
  private let recorder: CoordinatorCallRecorder
  private let cancelCurrentTaskAfterRead: Bool
  private(set) var readCount = 0

  init(
    items: [CurrentPlaybackItem],
    recorder: CoordinatorCallRecorder,
    cancelCurrentTaskAfterRead: Bool = false
  ) {
    self.items = items
    self.recorder = recorder
    self.cancelCurrentTaskAfterRead = cancelCurrentTaskAfterRead
  }

  func currentItem() async throws -> CurrentPlaybackItem {
    recorder.calls.append("playback")
    readCount += 1
    guard !items.isEmpty else {
      throw CurrentPlaybackError.nothingPlaying
    }
    let item = items.removeFirst()
    if cancelCurrentTaskAfterRead {
      withUnsafeCurrentTask { task in
        task?.cancel()
      }
    }
    return item
  }
}

@MainActor
private final class RecordingIdentityResolver: MusicIdentityResolving {
  private let identitiesBySourceID: [String: MusicIdentity]
  private let recorder: CoordinatorCallRecorder
  private(set) var receivedItems: [CurrentPlaybackItem] = []

  init(
    identitiesBySourceID: [String: MusicIdentity],
    recorder: CoordinatorCallRecorder
  ) {
    self.identitiesBySourceID = identitiesBySourceID
    self.recorder = recorder
  }

  func resolve(_ item: CurrentPlaybackItem) async throws -> MusicIdentity {
    recorder.calls.append("identity")
    receivedItems.append(item)
    guard let identity = identitiesBySourceID[item.sourceItemID] else {
      throw MusicIdentityError.noMatch
    }
    return identity
  }
}

@MainActor
private final class RecordingKnowledgeService: MusicKnowledgeServing {
  private let answersByArtistID: [String: KnowledgeAnswer]
  private let recorder: CoordinatorCallRecorder
  private(set) var receivedIdentities: [MusicIdentity] = []
  private(set) var receivedScopes: [KnowledgeScope] = []

  init(
    answersByArtistID: [String: KnowledgeAnswer],
    recorder: CoordinatorCallRecorder
  ) {
    self.answersByArtistID = answersByArtistID
    self.recorder = recorder
  }

  func overview(
    for identity: MusicIdentity,
    scope: KnowledgeScope
  ) async throws -> KnowledgeAnswer {
    recorder.calls.append("knowledge")
    receivedIdentities.append(identity)
    receivedScopes.append(scope)
    guard
      let artistID = identity.musicNerdArtistID,
      let answer = answersByArtistID[artistID]
    else {
      throw MusicKnowledgeError.noData
    }
    return answer
  }
}

private actor CoordinatorEmptyIdentityCrosswalk: MusicIdentityCrosswalkProviding {
  func entry(
    for playbackItem: CurrentPlaybackItem
  ) async -> MusicIdentityCrosswalkEntry? {
    nil
  }
}

@MainActor
private final class OfflineCoordinatorArtistLookup: ArtistIdentityLookingUp {
  private(set) var requestedNames: [String] = []

  func candidates(named artistName: String) async throws -> [ArtistIdentityCandidate] {
    requestedNames.append(artistName)
    throw MusicIdentityError.offline
  }
}

@MainActor
private final class OfflineCoordinatorKnowledgeLoader: ArtistKnowledgeLoading {
  private(set) var requestedArtistIDs: [String] = []

  func loadArtistKnowledge(
    artistID: String,
    artistName: String
  ) async throws -> ArtistKnowledgeRecord {
    requestedArtistIDs.append(artistID)
    throw MusicKnowledgeError.offline
  }
}
