import XCTest
@testable import MusicNerd

@MainActor
final class MusicNerdArtistIdentityLookupTests: XCTestCase {
  func testCandidatesPreserveEveryValidBackendResultInOrder() async throws {
    let service = ArtistIdentityServiceStub(
      searchResult: .success([
        makeArtist(id: "  artist-1  ", name: "  First Artist  "),
        makeArtist(id: "artist-2", name: "Second Artist"),
        makeArtist(id: "artist-3", name: "Third Artist")
      ])
    )
    let lookup = MusicNerdArtistIdentityLookup(musicNerdService: service)

    let candidates = try await lookup.candidates(named: "Requested Artist")

    XCTAssertEqual(
      candidates,
      [
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-1",
          canonicalName: "First Artist"
        ),
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-2",
          canonicalName: "Second Artist"
        ),
        ArtistIdentityCandidate(
          musicNerdArtistID: "artist-3",
          canonicalName: "Third Artist"
        )
      ]
    )
    let requestedNames = await service.requestedNames()
    XCTAssertEqual(requestedNames, ["Requested Artist"])
  }

  func testCandidatesFilterMissingOrBlankIDsAndNames() async throws {
    let service = ArtistIdentityServiceStub(
      searchResult: .success([
        makeArtist(id: nil, name: "Missing ID"),
        makeArtist(id: "", name: "Empty ID"),
        makeArtist(id: " \n\t ", name: "Blank ID"),
        makeArtist(id: "empty-name", name: ""),
        makeArtist(id: "blank-name", name: "  \n\t"),
        makeArtist(id: " valid-id ", name: " Valid Artist ")
      ])
    )
    let lookup = MusicNerdArtistIdentityLookup(musicNerdService: service)

    let candidates = try await lookup.candidates(named: "Valid Artist")

    XCTAssertEqual(
      candidates,
      [
        ArtistIdentityCandidate(
          musicNerdArtistID: "valid-id",
          canonicalName: "Valid Artist"
        )
      ]
    )
  }

  func testArtistNotFoundProducesNoCandidates() async throws {
    let service = ArtistIdentityServiceStub(
      searchResult: .failure(.musicNerdError(.artistNotFound))
    )
    let lookup = MusicNerdArtistIdentityLookup(musicNerdService: service)

    let candidates = try await lookup.candidates(named: "Unknown Artist")

    XCTAssertTrue(candidates.isEmpty)
  }

  func testNoConnectionMapsToOffline() async {
    let service = ArtistIdentityServiceStub(
      searchResult: .failure(.networkError(.noConnection))
    )
    let lookup = MusicNerdArtistIdentityLookup(musicNerdService: service)

    await assertFailure(
      from: lookup,
      expected: .offline
    )
  }

  func testNetworkTimeoutMapsToTimedOut() async {
    let service = ArtistIdentityServiceStub(
      searchResult: .failure(.networkError(.timeout))
    )
    let lookup = MusicNerdArtistIdentityLookup(musicNerdService: service)

    await assertFailure(
      from: lookup,
      expected: .timedOut
    )
  }

  func testOtherServiceFailuresMapToServiceUnavailable() async {
    let failures: [AppError] = [
      .networkError(.invalidResponse),
      .networkError(.serverError(503)),
      .networkError(.rateLimited),
      .networkError(.invalidURL),
      .musicNerdError(.apiError("backend failure")),
      .unknown("unexpected failure")
    ]

    for failure in failures {
      let service = ArtistIdentityServiceStub(
        searchResult: .failure(failure)
      )
      let lookup = MusicNerdArtistIdentityLookup(musicNerdService: service)

      await assertFailure(
        from: lookup,
        expected: .serviceUnavailable,
        sourceFailure: failure
      )
    }
  }

  private func assertFailure(
    from lookup: MusicNerdArtistIdentityLookup,
    expected expectedError: MusicIdentityError,
    sourceFailure: AppError? = nil
  ) async {
    do {
      _ = try await lookup.candidates(named: "Test Artist")
      XCTFail("Expected \(expectedError) for \(String(describing: sourceFailure))")
    } catch {
      XCTAssertEqual(
        error as? MusicIdentityError,
        expectedError,
        "Unexpected mapping for \(String(describing: sourceFailure))"
      )
    }
  }

  private func makeArtist(
    id: String?,
    name: String
  ) -> MusicNerdArtist {
    MusicNerdArtist(
      artistId: id,
      name: name,
      spotify: "ignored-spotify-value",
      instagram: nil,
      x: nil,
      youtube: nil,
      soundcloud: nil,
      bio: "ignored biography",
      youtubechannel: nil,
      tiktok: nil,
      bandcamp: nil,
      website: nil
    )
  }
}

private actor ArtistIdentityServiceStub: MusicNerdServiceProtocol {
  private let searchResult: Result<[MusicNerdArtist]>
  private var names: [String] = []

  init(searchResult: Result<[MusicNerdArtist]>) {
    self.searchResult = searchResult
  }

  func searchArtist(name: String) async -> Result<MusicNerdArtist> {
    .failure(.musicNerdError(.artistNotFound))
  }

  func searchArtists(name: String) async -> Result<[MusicNerdArtist]> {
    names.append(name)
    return searchResult
  }

  func getArtistBio(artistId: String) async -> Result<String> {
    .failure(.musicNerdError(.noBioAvailable))
  }

  func getFunFact(artistId: String, type: FunFactType) async -> Result<String> {
    .failure(.musicNerdError(.noFunFactAvailable))
  }

  func requestedNames() -> [String] {
    names
  }
}
