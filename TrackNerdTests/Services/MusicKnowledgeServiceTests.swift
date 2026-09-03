import XCTest
@testable import MusicNerd

@MainActor
final class MusicKnowledgeServiceTests: XCTestCase {
  func testFreshCacheHitRebasesAnswerAndSkipsLoader() async throws {
    let cachedIdentity = makeIdentity(sourceItemID: "cached-song")
    let currentIdentity = makeIdentity(sourceItemID: "current-song")
    let cachedAnswer = makeAnswer(identity: cachedIdentity)
    let cache = ExpiringCache<String, KnowledgeAnswer>()
    let now = Date(timeIntervalSince1970: 1_000)
    await cache.insert(
      cachedAnswer,
      for: "artist:artist-1",
      timeToLive: 60,
      now: now
    )
    let loader = MockArtistKnowledgeLoader(
      behavior: .record(makeRecord())
    )
    let service = makeService(loader: loader, cache: cache, now: now)

    let answer = try await service.overview(
      for: currentIdentity,
      scope: .artist
    )

    XCTAssertEqual(answer.source, .cache)
    XCTAssertEqual(answer.identity, currentIdentity)
    XCTAssertEqual(answer.spokenText, cachedAnswer.spokenText)
    XCTAssertEqual(loader.calls.count, 0)
  }

  func testExpiredCacheReloadsAndStoresFreshAnswer() async throws {
    let identity = makeIdentity()
    let cache = ExpiringCache<String, KnowledgeAnswer>()
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(61)
    await cache.insert(
      makeAnswer(identity: identity, spokenText: "Stale biography."),
      for: "artist:artist-1",
      timeToLive: 60,
      now: cachedAt
    )
    let loader = MockArtistKnowledgeLoader(
      behavior: .record(
        makeRecord(biography: "Fresh grounded biography.")
      )
    )
    let service = makeService(loader: loader, cache: cache, now: now)

    let answer = try await service.overview(for: identity, scope: .artist)

    XCTAssertEqual(answer.source, .musicNerdAPI)
    XCTAssertEqual(answer.spokenText, "Fresh grounded biography.")
    XCTAssertEqual(loader.calls.count, 1)

    let storedEntry = await cache.entry(for: "artist:artist-1")
    XCTAssertEqual(storedEntry?.value.spokenText, answer.spokenText)
    XCTAssertFalse(storedEntry?.isExpired(at: now) ?? true)
  }

  func testExpiredCacheFallsBackWhenLoaderIsOffline() async throws {
    let cachedIdentity = makeIdentity(sourceItemID: "cached-song")
    let currentIdentity = makeIdentity(sourceItemID: "current-song")
    let cache = ExpiringCache<String, KnowledgeAnswer>()
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(61)
    await cache.insert(
      makeAnswer(
        identity: cachedIdentity,
        spokenText: "Previously grounded biography."
      ),
      for: "artist:artist-1",
      timeToLive: 60,
      now: cachedAt
    )
    let loader = MockArtistKnowledgeLoader(behavior: .failure(.offline))
    let service = makeService(loader: loader, cache: cache, now: now)

    let answer = try await service.overview(
      for: currentIdentity,
      scope: .artist
    )

    XCTAssertEqual(answer.source, .staleCache)
    XCTAssertEqual(answer.identity, currentIdentity)
    XCTAssertEqual(answer.spokenText, "Previously grounded biography.")
    XCTAssertEqual(loader.calls.count, 1)
  }

  func testTimeoutWithoutStaleCacheThrowsTimedOut() async {
    let loader = MockArtistKnowledgeLoader(behavior: .waitForCancellation)
    let timeout = AsyncOperationTimeout(sleep: { _ in })
    let service = makeService(
      loader: loader,
      timeout: timeout,
      timeoutNanoseconds: 1
    )

    do {
      _ = try await service.overview(for: makeIdentity(), scope: .artist)
      XCTFail("Expected the knowledge request to time out")
    } catch {
      XCTAssertEqual(error as? MusicKnowledgeError, .timedOut)
    }

    XCTAssertEqual(loader.calls.count, 1)
  }

  func testCancellationPropagatesAndCancelsLoader() async {
    let loaderStarted = expectation(description: "loader started")
    let loader = MockArtistKnowledgeLoader(
      behavior: .waitForCancellation,
      onLoad: { loaderStarted.fulfill() }
    )
    let service = makeService(
      loader: loader,
      timeoutNanoseconds: 60_000_000_000
    )
    let identity = makeIdentity()

    let task = Task { @MainActor in
      try await service.overview(for: identity, scope: .artist)
    }
    await fulfillment(of: [loaderStarted], timeout: 1)
    task.cancel()

    do {
      _ = try await task.value
      XCTFail("Expected cancellation")
    } catch is CancellationError {
      // Expected.
    } catch {
      XCTFail("Expected CancellationError, got \(error)")
    }

    XCTAssertTrue(loader.observedCancellation)
  }

  func testLowConfidenceRefusesBeforeCallingLoader() async {
    let loader = MockArtistKnowledgeLoader(
      behavior: .record(makeRecord())
    )
    let service = makeService(loader: loader)

    do {
      _ = try await service.overview(
        for: makeIdentity(confidence: 0.89),
        scope: .artist
      )
      XCTFail("Expected low-confidence identity to be refused")
    } catch {
      XCTAssertEqual(error as? MusicKnowledgeError, .lowConfidence)
    }

    XCTAssertEqual(loader.calls.count, 0)
  }

  func testSongScopeRefusesBeforeCallingKnowledgeBackend() async {
    let loader = MockArtistKnowledgeLoader(
      behavior: .record(makeRecord())
    )
    let service = makeService(loader: loader)

    do {
      _ = try await service.overview(for: makeIdentity(), scope: .song)
      XCTFail("Expected song knowledge to remain unavailable")
    } catch {
      XCTAssertEqual(
        error as? MusicKnowledgeError,
        .songKnowledgeUnavailable
      )
    }

    XCTAssertEqual(loader.calls.count, 0)
  }

  private func makeService(
    loader: MockArtistKnowledgeLoader,
    cache: ExpiringCache<String, KnowledgeAnswer> = ExpiringCache(),
    timeout: AsyncOperationTimeout = AsyncOperationTimeout(),
    timeoutNanoseconds: UInt64 = 7_000_000_000,
    now: Date = Date(timeIntervalSince1970: 1_000)
  ) -> MusicKnowledgeService {
    MusicKnowledgeService(
      artistLoader: loader,
      cache: cache,
      timeout: timeout,
      timeoutNanoseconds: timeoutNanoseconds,
      cacheTimeToLive: 60,
      minimumConfidence: 0.9,
      now: { now }
    )
  }

  private func makeIdentity(
    sourceItemID: String = "song-1",
    confidence: Double = 1
  ) -> MusicIdentity {
    MusicIdentity(
      playbackItem: CurrentPlaybackItem(
        sourceItemID: sourceItemID,
        title: "Test Song",
        artistName: "Test Artist",
        albumTitle: "Test Album",
        kind: .song
      ),
      musicNerdSongID: nil,
      musicNerdArtistID: "artist-1",
      canonicalArtistName: "Test Artist",
      resolutionMethod: .normalizedArtistName,
      confidence: confidence
    )
  }

  private func makeRecord(
    biography: String? = "Grounded biography."
  ) -> ArtistKnowledgeRecord {
    ArtistKnowledgeRecord(
      artistID: "artist-1",
      artistName: "Test Artist",
      biography: biography,
      facts: []
    )
  }

  private func makeAnswer(
    identity: MusicIdentity,
    spokenText: String = "Cached grounded biography."
  ) -> KnowledgeAnswer {
    KnowledgeAnswer(
      scope: .artist,
      identity: identity,
      spokenText: spokenText,
      source: .musicNerdAPI
    )
  }
}

@MainActor
private final class MockArtistKnowledgeLoader: ArtistKnowledgeLoading {
  enum Behavior {
    case record(ArtistKnowledgeRecord)
    case failure(MusicKnowledgeError)
    case waitForCancellation
  }

  struct Call: Equatable {
    let artistID: String
    let artistName: String
  }

  private let behavior: Behavior
  private let onLoad: (() -> Void)?
  private(set) var calls: [Call] = []
  private(set) var observedCancellation = false

  init(
    behavior: Behavior,
    onLoad: (() -> Void)? = nil
  ) {
    self.behavior = behavior
    self.onLoad = onLoad
  }

  func loadArtistKnowledge(
    artistID: String,
    artistName: String
  ) async throws -> ArtistKnowledgeRecord {
    calls.append(Call(artistID: artistID, artistName: artistName))
    onLoad?()

    switch behavior {
    case .record(let record):
      return record
    case .failure(let error):
      throw error
    case .waitForCancellation:
      do {
        try await Task.sleep(nanoseconds: UInt64.max)
        throw MusicKnowledgeError.serviceUnavailable
      } catch is CancellationError {
        observedCancellation = true
        throw CancellationError()
      }
    }
  }
}
