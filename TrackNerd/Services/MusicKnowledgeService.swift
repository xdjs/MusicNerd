import Foundation

@MainActor
final class MusicKnowledgeService: MusicKnowledgeServing {
  private let artistLoader: any ArtistKnowledgeLoading
  private let composer: KnowledgeAnswerComposer
  private let cache: ExpiringCache<String, KnowledgeAnswer>
  private let timeout: AsyncOperationTimeout
  private let timeoutNanoseconds: UInt64
  private let cacheTimeToLive: TimeInterval
  private let minimumConfidence: Double
  private let now: @Sendable () -> Date

  init(
    artistLoader: any ArtistKnowledgeLoading,
    composer: KnowledgeAnswerComposer = KnowledgeAnswerComposer(),
    cache: ExpiringCache<String, KnowledgeAnswer> = ExpiringCache(),
    timeout: AsyncOperationTimeout = AsyncOperationTimeout(),
    timeoutNanoseconds: UInt64 = 7_000_000_000,
    cacheTimeToLive: TimeInterval = 300,
    minimumConfidence: Double = 0.9,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.artistLoader = artistLoader
    self.composer = composer
    self.cache = cache
    self.timeout = timeout
    self.timeoutNanoseconds = timeoutNanoseconds
    self.cacheTimeToLive = cacheTimeToLive
    self.minimumConfidence = minimumConfidence
    self.now = now
  }

  func overview(
    for identity: MusicIdentity,
    scope: KnowledgeScope
  ) async throws -> KnowledgeAnswer {
    try Task.checkCancellation()

    guard identity.confidence >= minimumConfidence else {
      throw MusicKnowledgeError.lowConfidence
    }
    guard scope == .artist else {
      throw MusicKnowledgeError.songKnowledgeUnavailable
    }
    guard
      let artistID = identity.musicNerdArtistID,
      let artistName = identity.canonicalArtistName ?? identity.playbackItem.artistName
    else {
      throw MusicKnowledgeError.missingArtistIdentity
    }

    let cacheKey = "artist:\(artistID)"
    let currentDate = now()
    let cached = await cache.entry(for: cacheKey)
    try Task.checkCancellation()

    if let cached, !cached.isExpired(at: currentDate) {
      return cached.value.rebased(on: identity, source: .cache)
    }

    do {
      let record = try await timeout.run(after: timeoutNanoseconds) {
        try await self.artistLoader.loadArtistKnowledge(
          artistID: artistID,
          artistName: artistName
        )
      }
      try Task.checkCancellation()

      let answer = try composer.compose(record: record, identity: identity)
      await cache.insert(
        answer,
        for: cacheKey,
        timeToLive: cacheTimeToLive,
        now: currentDate
      )
      try Task.checkCancellation()
      return answer
    } catch is CancellationError {
      throw CancellationError()
    } catch AsyncOperationTimeout.Failure.timedOut {
      return try staleFallback(cached, identity: identity, error: .timedOut)
    } catch let error as MusicKnowledgeError {
      switch error {
      case .offline, .timedOut:
        return try staleFallback(cached, identity: identity, error: error)
      default:
        throw error
      }
    } catch {
      throw MusicKnowledgeError.serviceUnavailable
    }
  }

  private func staleFallback(
    _ cached: ExpiringCache<String, KnowledgeAnswer>.Entry?,
    identity: MusicIdentity,
    error: MusicKnowledgeError
  ) throws -> KnowledgeAnswer {
    try Task.checkCancellation()
    guard let cached else { throw error }
    return cached.value.rebased(on: identity, source: .staleCache)
  }
}
