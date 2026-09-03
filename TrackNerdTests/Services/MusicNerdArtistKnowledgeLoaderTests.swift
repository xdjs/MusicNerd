import XCTest
@testable import MusicNerd

@MainActor
final class MusicNerdArtistKnowledgeLoaderTests: XCTestCase {
  func testLoaderUsesNonpersistentFetchMethods() async throws {
    let service = KnowledgeServiceStub(
      biography: .success("Fresh biography."),
      lore: .success("Fresh lore.")
    )
    let loader = MusicNerdArtistKnowledgeLoader(musicNerdService: service)

    let record = try await loader.loadArtistKnowledge(
      artistID: "artist-1",
      artistName: "Test Artist"
    )

    let calls = await service.callCounts()
    XCTAssertEqual(calls.getBiography, 0)
    XCTAssertEqual(calls.getLore, 0)
    XCTAssertEqual(calls.fetchBiography, 1)
    XCTAssertEqual(calls.fetchLore, 1)
    XCTAssertEqual(record.biography, "Fresh biography.")
    XCTAssertEqual(record.facts, ["Fresh lore."])
  }

  func testPartialFetchProducesAvailableKnowledge() async throws {
    let service = KnowledgeServiceStub(
      biography: .success("Fresh biography."),
      lore: .failure(.musicNerdError(.noFunFactAvailable))
    )
    let loader = MusicNerdArtistKnowledgeLoader(musicNerdService: service)

    let record = try await loader.loadArtistKnowledge(
      artistID: "artist-1",
      artistName: "Test Artist"
    )

    XCTAssertEqual(record.biography, "Fresh biography.")
    XCTAssertTrue(record.facts.isEmpty)
  }

  func testOfflineFailuresRemainTyped() async {
    let service = KnowledgeServiceStub(
      biography: .failure(.networkError(.noConnection)),
      lore: .failure(.musicNerdError(.noFunFactAvailable))
    )
    let loader = MusicNerdArtistKnowledgeLoader(musicNerdService: service)

    do {
      _ = try await loader.loadArtistKnowledge(
        artistID: "artist-1",
        artistName: "Test Artist"
      )
      XCTFail("Expected offline failure")
    } catch {
      XCTAssertEqual(error as? MusicKnowledgeError, .offline)
    }
  }

  func testUnavailableBiographyAndLoreProduceNoData() async {
    let service = KnowledgeServiceStub(
      biography: .failure(.musicNerdError(.noBioAvailable)),
      lore: .failure(.musicNerdError(.noFunFactAvailable))
    )
    let loader = MusicNerdArtistKnowledgeLoader(musicNerdService: service)

    do {
      _ = try await loader.loadArtistKnowledge(
        artistID: "artist-1",
        artistName: "Test Artist"
      )
      XCTFail("Expected no-data failure")
    } catch {
      XCTAssertEqual(error as? MusicKnowledgeError, .noData)
    }
  }
}

private actor KnowledgeServiceStub: MusicNerdServiceProtocol {
  private let biography: Result<String>
  private let lore: Result<String>
  private var getBiographyCalls = 0
  private var getLoreCalls = 0
  private var fetchBiographyCalls = 0
  private var fetchLoreCalls = 0

  init(
    biography: Result<String>,
    lore: Result<String>
  ) {
    self.biography = biography
    self.lore = lore
  }

  func searchArtist(name: String) async -> Result<MusicNerdArtist> {
    .failure(.musicNerdError(.artistNotFound))
  }

  func getArtistBio(artistId: String) async -> Result<String> {
    getBiographyCalls += 1
    return biography
  }

  func fetchArtistBio(artistId: String) async -> Result<String> {
    fetchBiographyCalls += 1
    return biography
  }

  func getFunFact(artistId: String, type: FunFactType) async -> Result<String> {
    getLoreCalls += 1
    return lore
  }

  func fetchFunFact(
    artistId: String,
    type: FunFactType
  ) async -> Result<String> {
    fetchLoreCalls += 1
    return lore
  }

  func callCounts() -> (
    getBiography: Int,
    getLore: Int,
    fetchBiography: Int,
    fetchLore: Int
  ) {
    (
      getBiographyCalls,
      getLoreCalls,
      fetchBiographyCalls,
      fetchLoreCalls
    )
  }
}
