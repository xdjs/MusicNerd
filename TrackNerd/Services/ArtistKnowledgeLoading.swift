import Foundation

@MainActor
protocol ArtistKnowledgeLoading: Sendable {
  func loadArtistKnowledge(
    artistID: String,
    artistName: String
  ) async throws -> ArtistKnowledgeRecord
}
