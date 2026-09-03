import Foundation

@MainActor
struct MusicIdentityResolver: MusicIdentityResolving {
  private let crosswalk: any MusicIdentityCrosswalkProviding
  private let artistLookup: any ArtistIdentityLookingUp
  private let normalizer: ArtistNameNormalizer
  private let cache: ExpiringCache<String, MusicIdentity>
  private let timeout: AsyncOperationTimeout
  private let timeoutNanoseconds: UInt64
  private let cacheTimeToLive: TimeInterval
  private let minimumConfidence: Double
  private let now: @Sendable () -> Date

  init(
    crosswalk: any MusicIdentityCrosswalkProviding,
    artistLookup: any ArtistIdentityLookingUp,
    normalizer: ArtistNameNormalizer = ArtistNameNormalizer(),
    cache: ExpiringCache<String, MusicIdentity> = ExpiringCache(),
    timeout: AsyncOperationTimeout = AsyncOperationTimeout(),
    timeoutNanoseconds: UInt64 = 3_000_000_000,
    cacheTimeToLive: TimeInterval = 300,
    minimumConfidence: Double = 0.9,
    now: @escaping @Sendable () -> Date = { Date() }
  ) {
    self.crosswalk = crosswalk
    self.artistLookup = artistLookup
    self.normalizer = normalizer
    self.cache = cache
    self.timeout = timeout
    self.timeoutNanoseconds = timeoutNanoseconds
    self.cacheTimeToLive = cacheTimeToLive
    self.minimumConfidence = minimumConfidence
    self.now = now
  }

  func resolve(_ item: CurrentPlaybackItem) async throws -> MusicIdentity {
    try Task.checkCancellation()
    let currentDate = now()
    let cached = await cache.entry(for: item.stableIdentity)

    if
      let cached,
      cached.value.playbackItem.stableIdentity == item.stableIdentity,
      !cached.isExpired(at: currentDate)
    {
      try Task.checkCancellation()
      return identity(rebasing: cached.value, on: item)
    }
    let expiredIdentity = expiredIdentity(
      from: cached,
      for: item,
      at: currentDate
    )

    if let crosswalkEntry = await crosswalk.entry(for: item) {
      try Task.checkCancellation()
      let identity = MusicIdentity(
        playbackItem: item,
        musicNerdSongID: crosswalkEntry.musicNerdSongID,
        musicNerdArtistID: crosswalkEntry.musicNerdArtistID,
        canonicalArtistName: crosswalkEntry.canonicalArtistName,
        resolutionMethod: .appleMusicCrosswalk,
        confidence: 1
      )
      await store(identity, for: item, now: currentDate)
      try Task.checkCancellation()
      return identity
    }

    guard let artistName = item.artistName else {
      throw MusicIdentityError.missingArtistMetadata
    }

    let candidates: [ArtistIdentityCandidate]
    do {
      candidates = try await timeout.run(after: timeoutNanoseconds) {
        try await self.artistLookup.candidates(named: artistName)
      }
    } catch is CancellationError {
      throw CancellationError()
    } catch AsyncOperationTimeout.Failure.timedOut {
      if let expiredIdentity {
        try Task.checkCancellation()
        return expiredIdentity
      }
      throw MusicIdentityError.timedOut
    } catch let error as MusicIdentityError {
      switch error {
      case .offline, .timedOut:
        if let expiredIdentity {
          try Task.checkCancellation()
          return expiredIdentity
        }
      default:
        break
      }
      throw error
    } catch {
      throw MusicIdentityError.serviceUnavailable
    }
    try Task.checkCancellation()

    guard !candidates.isEmpty else {
      throw MusicIdentityError.noMatch
    }

    let scoredCandidates = candidates.map { candidate in
      (
        candidate: candidate,
        confidence: normalizer.confidence(
          for: artistName,
          candidateName: candidate.canonicalName
        )
      )
    }
    let acceptedCandidates = scoredCandidates.filter {
      $0.confidence >= minimumConfidence
    }
    let uniqueAcceptedIDs = Set(
      acceptedCandidates.map(\.candidate.musicNerdArtistID)
    )

    guard !acceptedCandidates.isEmpty else {
      let highestConfidence = scoredCandidates.map(\.confidence).max() ?? 0
      throw MusicIdentityError.belowConfidenceThreshold(
        score: highestConfidence
      )
    }
    guard uniqueAcceptedIDs.count == 1 else {
      throw MusicIdentityError.ambiguousMatch
    }

    let match = acceptedCandidates[0]
    let identity = MusicIdentity(
      playbackItem: item,
      musicNerdSongID: nil,
      musicNerdArtistID: match.candidate.musicNerdArtistID,
      canonicalArtistName: match.candidate.canonicalName,
      resolutionMethod: .normalizedArtistName,
      confidence: match.confidence
    )
    await store(identity, for: item, now: currentDate)
    try Task.checkCancellation()
    return identity
  }

  private func expiredIdentity(
    from cached: ExpiringCache<String, MusicIdentity>.Entry?,
    for item: CurrentPlaybackItem,
    at date: Date
  ) -> MusicIdentity? {
    guard
      let cached,
      cached.isExpired(at: date),
      cached.value.playbackItem.stableIdentity == item.stableIdentity
    else {
      return nil
    }

    return identity(rebasing: cached.value, on: item)
  }

  private func identity(
    rebasing identity: MusicIdentity,
    on item: CurrentPlaybackItem
  ) -> MusicIdentity {
    return MusicIdentity(
      playbackItem: item,
      musicNerdSongID: identity.musicNerdSongID,
      musicNerdArtistID: identity.musicNerdArtistID,
      canonicalArtistName: identity.canonicalArtistName,
      resolutionMethod: identity.resolutionMethod,
      confidence: identity.confidence
    )
  }

  private func store(
    _ identity: MusicIdentity,
    for item: CurrentPlaybackItem,
    now: Date
  ) async {
    await cache.insert(
      identity,
      for: item.stableIdentity,
      timeToLive: cacheTimeToLive,
      now: now
    )
  }
}
