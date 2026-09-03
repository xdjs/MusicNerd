import Foundation
import XCTest
@testable import MusicNerd

@MainActor
final class MusicIdentityResolverTests: XCTestCase {
  func testExactCrosswalkWinsWithoutArtistLookup() async throws {
    let item = makePlaybackItem(
      sourceItemID: "song-123",
      artistName: "Playback Artist"
    )
    let crosswalk = IdentityCrosswalkStub(
      entry: MusicIdentityCrosswalkEntry(
        sourceItemID: "song-123",
        sourceKind: .song,
        musicNerdSongID: "music-nerd-song-1",
        musicNerdArtistID: "music-nerd-artist-1",
        canonicalArtistName: "Canonical Artist"
      )
    )
    let artistLookup = ArtistLookupStub(candidates: [])
    let resolver = MusicIdentityResolver(
      crosswalk: crosswalk,
      artistLookup: artistLookup
    )

    let identity = try await resolver.resolve(item)

    XCTAssertEqual(identity.playbackItem, item)
    XCTAssertEqual(identity.musicNerdSongID, "music-nerd-song-1")
    XCTAssertEqual(identity.musicNerdArtistID, "music-nerd-artist-1")
    XCTAssertEqual(identity.canonicalArtistName, "Canonical Artist")
    XCTAssertEqual(identity.resolutionMethod, .appleMusicCrosswalk)
    XCTAssertEqual(identity.confidence, 1)
    XCTAssertEqual(artistLookup.requestedNames, [])
  }

  func testExactNormalizedArtistMatchResolvesStableArtistIdentity() async throws {
    let crosswalk = IdentityCrosswalkStub(entry: nil)
    let artistLookup = ArtistLookupStub(
      candidates: [
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-beyonce",
          canonicalName: "Beyonce"
        )
      ]
    )
    let resolver = MusicIdentityResolver(
      crosswalk: crosswalk,
      artistLookup: artistLookup
    )
    let item = makePlaybackItem(artistName: "The Beyoncé")

    let identity = try await resolver.resolve(item)

    XCTAssertEqual(identity.musicNerdSongID, nil)
    XCTAssertEqual(identity.musicNerdArtistID, "artist-beyonce")
    XCTAssertEqual(identity.canonicalArtistName, "Beyonce")
    XCTAssertEqual(identity.resolutionMethod, .normalizedArtistName)
    XCTAssertEqual(identity.confidence, 0.95)
    XCTAssertEqual(artistLookup.requestedNames, ["The Beyoncé"])
  }

  func testMultipleAcceptedArtistIDsAreRejectedAsAmbiguous() async {
    let artistLookup = ArtistLookupStub(
      candidates: [
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-1",
          canonicalName: "The National"
        ),
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-2",
          canonicalName: "National"
        )
      ]
    )
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup
    )

    do {
      _ = try await resolver.resolve(
        makePlaybackItem(artistName: "The National")
      )
      XCTFail("Expected ambiguousMatch")
    } catch {
      XCTAssertEqual(error as? MusicIdentityError, .ambiguousMatch)
    }
  }

  func testCandidateBelowMinimumConfidenceIsRejected() async {
    let artistLookup = ArtistLookupStub(
      candidates: [
        ArtistIdentityCandidate(
          musicNerdArtistID: "tribute-artist",
          canonicalName: "Radiohead Tribute Band"
        )
      ]
    )
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup,
      minimumConfidence: 0.9
    )

    do {
      _ = try await resolver.resolve(makePlaybackItem(artistName: "Radiohead"))
      XCTFail("Expected belowConfidenceThreshold")
    } catch let MusicIdentityError.belowConfidenceThreshold(score) {
      XCTAssertGreaterThan(score, 0)
      XCTAssertLessThan(score, 0.9)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCachedIdentitySkipsDependenciesUntilEntryExpires() async throws {
    let clock = TestDateProvider(
      initialDate: Date(timeIntervalSince1970: 1_000)
    )
    let cache = ExpiringCache<String, MusicIdentity>()
    let crosswalk = IdentityCrosswalkStub(entry: nil)
    let artistLookup = ArtistLookupStub(
      candidates: [
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-1",
          canonicalName: "Test Artist"
        )
      ]
    )
    let resolver = MusicIdentityResolver(
      crosswalk: crosswalk,
      artistLookup: artistLookup,
      cache: cache,
      cacheTimeToLive: 10,
      now: { clock.now() }
    )
    let item = makePlaybackItem(artistName: "Test Artist")

    let initialIdentity = try await resolver.resolve(item)
    let cachedIdentity = try await resolver.resolve(item)

    XCTAssertEqual(cachedIdentity, initialIdentity)
    let requestCountBeforeExpiry = await crosswalk.requestCount()
    XCTAssertEqual(requestCountBeforeExpiry, 1)
    XCTAssertEqual(artistLookup.requestedNames.count, 1)

    clock.advance(by: 10)
    let refreshedIdentity = try await resolver.resolve(item)

    XCTAssertEqual(refreshedIdentity, initialIdentity)
    let requestCountAfterExpiry = await crosswalk.requestCount()
    XCTAssertEqual(requestCountAfterExpiry, 2)
    XCTAssertEqual(artistLookup.requestedNames.count, 2)
  }

  func testFreshCachedIdentityUsesCurrentPlaybackMetadataForSameStableItem() async throws {
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let cache = ExpiringCache<String, MusicIdentity>()
    let originalItem = CurrentPlaybackItem(
      sourceItemID: "song-1",
      title: "Original Title",
      artistName: "Original Artist",
      albumTitle: "Original Album",
      kind: .song
    )
    let currentItem = CurrentPlaybackItem(
      sourceItemID: "song-1",
      title: "Updated Title",
      artistName: "Updated Artist",
      albumTitle: "Updated Album",
      kind: .song
    )
    let cachedIdentity = MusicIdentity(
      playbackItem: originalItem,
      musicNerdSongID: "song-id",
      musicNerdArtistID: "artist-id",
      canonicalArtistName: "Canonical Artist",
      resolutionMethod: .appleMusicCrosswalk,
      confidence: 1
    )
    await cache.insert(
      cachedIdentity,
      for: originalItem.stableIdentity,
      timeToLive: 300,
      now: cachedAt
    )
    let crosswalk = IdentityCrosswalkStub(entry: nil)
    let artistLookup = ArtistLookupStub(candidates: [])
    let resolver = MusicIdentityResolver(
      crosswalk: crosswalk,
      artistLookup: artistLookup,
      cache: cache,
      now: { cachedAt.addingTimeInterval(1) }
    )

    let identity = try await resolver.resolve(currentItem)

    XCTAssertEqual(identity.playbackItem, currentItem)
    XCTAssertEqual(identity.musicNerdSongID, cachedIdentity.musicNerdSongID)
    XCTAssertEqual(identity.musicNerdArtistID, cachedIdentity.musicNerdArtistID)
    XCTAssertEqual(
      identity.canonicalArtistName,
      cachedIdentity.canonicalArtistName
    )
    XCTAssertEqual(identity.resolutionMethod, cachedIdentity.resolutionMethod)
    XCTAssertEqual(identity.confidence, cachedIdentity.confidence)
    let crosswalkRequestCount = await crosswalk.requestCount()
    XCTAssertEqual(crosswalkRequestCount, 0)
    XCTAssertEqual(artistLookup.requestedNames, [])
  }

  func testArtistLookupTimeoutMapsToIdentityTimeout() async {
    let artistLookup = ArtistLookupStub(
      delayNanoseconds: 10_000_000_000,
      candidates: []
    )
    let immediateTimeout = AsyncOperationTimeout(sleep: { _ in })
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup,
      timeout: immediateTimeout,
      timeoutNanoseconds: 1
    )

    do {
      _ = try await resolver.resolve(makePlaybackItem())
      XCTFail("Expected timedOut")
    } catch {
      XCTAssertEqual(error as? MusicIdentityError, .timedOut)
    }
  }

  func testExpiredIdentityFallsBackWhenRefreshIsOffline() async throws {
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(11)
    let cache = ExpiringCache<String, MusicIdentity>()
    let item = makePlaybackItem(artistName: "Test Artist")
    let staleIdentity = makeIdentity(
      playbackItem: item,
      artistID: "artist-1"
    )
    await cache.insert(
      staleIdentity,
      for: item.stableIdentity,
      timeToLive: 10,
      now: cachedAt
    )
    let artistLookup = ArtistLookupStub(
      error: .offline,
      candidates: []
    )
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup,
      cache: cache,
      now: { now }
    )

    let identity = try await resolver.resolve(item)

    XCTAssertEqual(identity, staleIdentity)
    XCTAssertEqual(artistLookup.requestedNames, ["Test Artist"])
  }

  func testExpiredIdentityFallsBackWhenRefreshTimesOut() async throws {
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(11)
    let cache = ExpiringCache<String, MusicIdentity>()
    let item = makePlaybackItem(artistName: "Test Artist")
    let staleIdentity = makeIdentity(
      playbackItem: item,
      artistID: "artist-1"
    )
    await cache.insert(
      staleIdentity,
      for: item.stableIdentity,
      timeToLive: 10,
      now: cachedAt
    )
    let artistLookup = ArtistLookupStub(
      delayNanoseconds: 10_000_000_000,
      candidates: []
    )
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup,
      cache: cache,
      timeout: AsyncOperationTimeout(sleep: { _ in }),
      timeoutNanoseconds: 1,
      now: { now }
    )

    let identity = try await resolver.resolve(item)

    XCTAssertEqual(identity, staleIdentity)
    XCTAssertEqual(artistLookup.requestedNames, ["Test Artist"])
  }

  func testExpiredIdentityDoesNotMaskAmbiguousRefresh() async {
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(11)
    let cache = ExpiringCache<String, MusicIdentity>()
    let item = makePlaybackItem(artistName: "The National")
    await cache.insert(
      makeIdentity(playbackItem: item, artistID: "old-artist"),
      for: item.stableIdentity,
      timeToLive: 10,
      now: cachedAt
    )
    let artistLookup = ArtistLookupStub(
      candidates: [
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-1",
          canonicalName: "The National"
        ),
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-2",
          canonicalName: "National"
        )
      ]
    )
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup,
      cache: cache,
      now: { now }
    )

    do {
      _ = try await resolver.resolve(item)
      XCTFail("Expected ambiguousMatch")
    } catch {
      XCTAssertEqual(error as? MusicIdentityError, .ambiguousMatch)
    }
  }

  func testExpiredIdentityFromDifferentPlaybackItemDoesNotFallback() async {
    let cachedAt = Date(timeIntervalSince1970: 1_000)
    let now = cachedAt.addingTimeInterval(11)
    let cache = ExpiringCache<String, MusicIdentity>()
    let currentItem = makePlaybackItem(
      sourceItemID: "current-song",
      artistName: "Current Artist"
    )
    let otherItem = makePlaybackItem(
      sourceItemID: "other-song",
      artistName: "Other Artist"
    )
    await cache.insert(
      makeIdentity(playbackItem: otherItem, artistID: "other-artist"),
      for: currentItem.stableIdentity,
      timeToLive: 10,
      now: cachedAt
    )
    let artistLookup = ArtistLookupStub(error: .offline, candidates: [])
    let resolver = MusicIdentityResolver(
      crosswalk: IdentityCrosswalkStub(entry: nil),
      artistLookup: artistLookup,
      cache: cache,
      now: { now }
    )

    do {
      _ = try await resolver.resolve(currentItem)
      XCTFail("Expected offline")
    } catch {
      XCTAssertEqual(error as? MusicIdentityError, .offline)
    }
  }

  func testCancellationPropagatesWithoutCallingDependencies() async {
    let crosswalk = IdentityCrosswalkStub(entry: nil)
    let artistLookup = ArtistLookupStub(candidates: [])
    let resolver = MusicIdentityResolver(
      crosswalk: crosswalk,
      artistLookup: artistLookup
    )

    let task = Task { @MainActor () throws -> MusicIdentity in
      withUnsafeCurrentTask { currentTask in
        currentTask?.cancel()
      }
      return try await resolver.resolve(makePlaybackItem())
    }

    do {
      _ = try await task.value
      XCTFail("Expected cancellation")
    } catch is CancellationError {
      // Expected.
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    let crosswalkRequestCount = await crosswalk.requestCount()
    XCTAssertEqual(crosswalkRequestCount, 0)
    XCTAssertEqual(artistLookup.requestedNames, [])
  }

  private func makePlaybackItem(
    sourceItemID: String = "song-1",
    artistName: String? = "Test Artist"
  ) -> CurrentPlaybackItem {
    CurrentPlaybackItem(
      sourceItemID: sourceItemID,
      title: "Test Song",
      artistName: artistName,
      albumTitle: "Test Album",
      kind: .song
    )
  }

  private func makeIdentity(
    playbackItem: CurrentPlaybackItem,
    artistID: String
  ) -> MusicIdentity {
    MusicIdentity(
      playbackItem: playbackItem,
      musicNerdSongID: nil,
      musicNerdArtistID: artistID,
      canonicalArtistName: playbackItem.artistName,
      resolutionMethod: .normalizedArtistName,
      confidence: 1
    )
  }
}

private actor IdentityCrosswalkStub: MusicIdentityCrosswalkProviding {
  private let result: MusicIdentityCrosswalkEntry?
  private var requests = 0

  init(entry: MusicIdentityCrosswalkEntry?) {
    self.result = entry
  }

  func entry(
    for playbackItem: CurrentPlaybackItem
  ) async -> MusicIdentityCrosswalkEntry? {
    requests += 1
    return result
  }

  func requestCount() -> Int {
    requests
  }
}

@MainActor
private final class ArtistLookupStub: ArtistIdentityLookingUp {
  private let delayNanoseconds: UInt64?
  private let error: MusicIdentityError?
  private let result: [ArtistIdentityCandidate]
  private(set) var requestedNames: [String] = []

  init(
    delayNanoseconds: UInt64? = nil,
    error: MusicIdentityError? = nil,
    candidates: [ArtistIdentityCandidate]
  ) {
    self.delayNanoseconds = delayNanoseconds
    self.error = error
    self.result = candidates
  }

  func candidates(named artistName: String) async throws -> [ArtistIdentityCandidate] {
    requestedNames.append(artistName)
    if let delayNanoseconds {
      try await Task.sleep(nanoseconds: delayNanoseconds)
    }
    if let error {
      throw error
    }
    return result
  }
}

private final class TestDateProvider: @unchecked Sendable {
  private let lock = NSLock()
  private var date: Date

  init(initialDate: Date) {
    self.date = initialDate
  }

  func now() -> Date {
    lock.withLock { date }
  }

  func advance(by interval: TimeInterval) {
    lock.withLock {
      date = date.addingTimeInterval(interval)
    }
  }
}
