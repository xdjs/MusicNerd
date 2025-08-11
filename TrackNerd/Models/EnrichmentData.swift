import Foundation
import SwiftData

@Model
final class EnrichmentData {
    var artistBio: String?
    var songTrivia: String?
    var funFact: String? // Legacy single fun fact for backward compatibility
    var funFacts: [String: String] // Categorized fun facts by type
    var relatedArtists: [String]
    var relatedSongs: [String]
    var genres: [String]
    var releaseYear: Int?
    var albumName: String?
    var enrichedAt: Date
    
    // Error tracking for fallback content (stored as JSON strings for SwiftData compatibility)
    @Attribute(.externalStorage) var bioErrorData: Data?
    @Attribute(.externalStorage) var funFactErrorsData: Data?
    
    init(
        artistBio: String? = nil,
        songTrivia: String? = nil,
        funFact: String? = nil,
        funFacts: [String: String] = [:],
        relatedArtists: [String] = [],
        relatedSongs: [String] = [],
        genres: [String] = [],
        releaseYear: Int? = nil,
        albumName: String? = nil,
        bioError: EnrichmentError? = nil,
        funFactErrors: [String: EnrichmentError] = [:]
    ) {
        self.artistBio = artistBio
        self.songTrivia = songTrivia
        self.funFact = funFact
        self.funFacts = funFacts
        self.relatedArtists = relatedArtists
        self.relatedSongs = relatedSongs
        self.genres = genres
        self.releaseYear = releaseYear
        self.albumName = albumName
        self.enrichedAt = Date()
        
        // Encode errors as JSON data for SwiftData storage
        if let bioError = bioError {
            self.bioErrorData = try? JSONEncoder().encode(bioError)
        } else {
            self.bioErrorData = nil
        }
        
        if !funFactErrors.isEmpty {
            self.funFactErrorsData = try? JSONEncoder().encode(funFactErrors)
        } else {
            self.funFactErrorsData = nil
        }
    }
}

extension EnrichmentData {
    // Computed properties for error handling (backward compatibility)
    var bioError: EnrichmentError? {
        guard let data = bioErrorData else { return nil }
        return try? JSONDecoder().decode(EnrichmentError.self, from: data)
    }
    
    var funFactErrors: [String: EnrichmentError] {
        guard let data = funFactErrorsData else { return [:] }
        return (try? JSONDecoder().decode([String: EnrichmentError].self, from: data)) ?? [:]
    }
    
    var hasArtistInfo: Bool {
        artistBio != nil || !genres.isEmpty || !relatedArtists.isEmpty
    }
    
    var hasSongInfo: Bool {
        songTrivia != nil || funFact != nil || !funFacts.isEmpty || !relatedSongs.isEmpty || albumName != nil
    }
    
    var isEmpty: Bool {
        artistBio == nil && 
        songTrivia == nil && 
        funFact == nil && 
        funFacts.isEmpty &&
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
    
    // MARK: - Fun Facts Helpers
    
    var hasAnyFunFacts: Bool {
        funFact != nil || !funFacts.isEmpty
    }
    
    func funFact(for type: String) -> String? {
        return funFacts[type]
    }
    
    var availableFunFactTypes: [String] {
        return Array(funFacts.keys).sorted()
    }
    
    // Convenience getters for specific fun fact types
    var loreFact: String? { funFacts["lore"] }
    var btsFact: String? { funFacts["bts"] }
    var activityFact: String? { funFacts["activity"] }
    var surpriseFact: String? { funFacts["surprise"] }
}