import Foundation

@MainActor
final class MusicNerdArtistKnowledgeLoader: ArtistKnowledgeLoading {
  private let musicNerdService: any MusicNerdServiceProtocol

  init(musicNerdService: any MusicNerdServiceProtocol) {
    self.musicNerdService = musicNerdService
  }

  func loadArtistKnowledge(
    artistID: String,
    artistName: String
  ) async throws -> ArtistKnowledgeRecord {
    try Task.checkCancellation()

    async let biographyResult = musicNerdService.fetchArtistBio(
      artistId: artistID
    )
    async let loreResult = musicNerdService.fetchFunFact(
      artistId: artistID,
      type: .lore
    )

    let (biography, lore) = await (biographyResult, loreResult)
    try Task.checkCancellation()

    let biographyText = try? biography.get()
    let loreText = try? lore.get()
    let facts = [loreText].compactMap { $0 }

    guard biographyText != nil || !facts.isEmpty else {
      throw Self.mapFailures([biography, lore])
    }

    return ArtistKnowledgeRecord(
      artistID: artistID,
      artistName: artistName,
      biography: biographyText,
      facts: facts
    )
  }

  private static func mapFailures<T>(_ results: [Result<T>]) -> MusicKnowledgeError {
    let errors = results.compactMap { result -> AppError? in
      guard case .failure(let error) = result else { return nil }
      return error
    }

    if errors.contains(.networkError(.noConnection)) {
      return .offline
    }
    if errors.contains(.networkError(.timeout)) {
      return .timedOut
    }
    if errors.allSatisfy({ error in
      switch error {
      case .musicNerdError(.noBioAvailable),
           .musicNerdError(.noFunFactAvailable),
           .musicNerdError(.artistNotFound):
        return true
      default:
        return false
      }
    }) {
      return .noData
    }
    return .serviceUnavailable
  }
}
