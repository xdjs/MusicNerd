import Foundation

@MainActor
final class MusicNerdArtistIdentityLookup: ArtistIdentityLookingUp {
  private let musicNerdService: any MusicNerdServiceProtocol

  init(musicNerdService: any MusicNerdServiceProtocol) {
    self.musicNerdService = musicNerdService
  }

  func candidates(named artistName: String) async throws -> [ArtistIdentityCandidate] {
    try Task.checkCancellation()
    let result = await musicNerdService.searchArtists(name: artistName)
    try Task.checkCancellation()

    switch result {
    case .success(let artists):
      return artists.compactMap { artist in
        guard
          let artistID = artist.artistId?.trimmingCharacters(in: .whitespacesAndNewlines),
          !artistID.isEmpty
        else {
          return nil
        }

        let canonicalName = artist.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !canonicalName.isEmpty else { return nil }

        return ArtistIdentityCandidate(
          musicNerdArtistID: artistID,
          canonicalName: canonicalName
        )
      }

    case .failure(.networkError(.noConnection)):
      throw MusicIdentityError.offline
    case .failure(.networkError(.timeout)):
      throw MusicIdentityError.timedOut
    case .failure(.musicNerdError(.artistNotFound)):
      return []
    case .failure:
      throw MusicIdentityError.serviceUnavailable
    }
  }
}
