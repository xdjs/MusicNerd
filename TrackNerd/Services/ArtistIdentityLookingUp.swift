import Foundation

@MainActor
protocol ArtistIdentityLookingUp: Sendable {
  func candidates(named artistName: String) async throws -> [ArtistIdentityCandidate]
}
