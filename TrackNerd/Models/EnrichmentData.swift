import Foundation

struct EnrichmentData: Codable, Hashable {
    let artistBio: String?
    let songTrivia: String?
    let funFact: String?
    let relatedArtists: [String]
    let relatedSongs: [String]
    let genres: [String]
    let releaseYear: Int?
    let albumName: String?
    let enrichedAt: Date
    
    init(
        artistBio: String? = nil,
        songTrivia: String? = nil,
        funFact: String? = nil,
        relatedArtists: [String] = [],
        relatedSongs: [String] = [],
        genres: [String] = [],
        releaseYear: Int? = nil,
        albumName: String? = nil
    ) {
        self.artistBio = artistBio
        self.songTrivia = songTrivia
        self.funFact = funFact
        self.relatedArtists = relatedArtists
        self.relatedSongs = relatedSongs
        self.genres = genres
        self.releaseYear = releaseYear
        self.albumName = albumName
        self.enrichedAt = Date()
    }
}

extension EnrichmentData {
    var hasArtistInfo: Bool {
        artistBio != nil || !genres.isEmpty || !relatedArtists.isEmpty
    }
    
    var hasSongInfo: Bool {
        songTrivia != nil || funFact != nil || !relatedSongs.isEmpty || albumName != nil
    }
    
    var isEmpty: Bool {
        artistBio == nil && 
        songTrivia == nil && 
        funFact == nil && 
        relatedArtists.isEmpty && 
        relatedSongs.isEmpty && 
        genres.isEmpty && 
        releaseYear == nil && 
        albumName == nil
    }
    
    var formattedReleaseInfo: String? {
        guard let year = releaseYear else { return albumName }
        guard let album = albumName else { return "\(year)" }
        return "\(album) (\(year))"
    }
}