import Foundation

// MARK: - Search Artists Response

struct SearchArtistsRequest: Codable {
    let query: String
}

struct SearchArtistsResponse: Codable {
    let results: [MusicNerdArtist]
}

struct MusicNerdArtist: Codable, Identifiable {
    let id: Int
    let name: String
    let spotify: String?
    let instagram: String?
    let x: String?
    let youtube: String?
    let soundcloud: String?
    let bio: String?
    
    // Additional fields that might be present
    let youtubechannel: String?
    let tiktok: String?
    let bandcamp: String?
    let website: String?
}

// MARK: - Artist Bio Response

struct ArtistBioResponse: Codable {
    let bio: String?
    let artist: MusicNerdArtist?
}

// MARK: - Fun Facts Response

struct FunFactsResponse: Codable {
    let funFact: String?
    let artist: MusicNerdArtist?
}

// MARK: - API Error Response

struct MusicNerdAPIError: Codable, Error {
    let error: String
    let message: String?
}

// MARK: - Result Types

enum MusicNerdResult<T> {
    case success(T)
    case failure(MusicNerdAPIError)
}

// MARK: - Extensions

extension MusicNerdArtist {
    var displayName: String {
        return name
    }
    
    var hasData: Bool {
        return bio != nil || spotify != nil || instagram != nil || x != nil || youtube != nil || soundcloud != nil
    }
}