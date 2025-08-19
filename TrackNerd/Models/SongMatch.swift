import Foundation
import SwiftData

@Model
final class SongMatch {
    var id: UUID
    var title: String
    var artist: String
    var album: String?
    var albumArtURL: String?
    var appleMusicID: String?
    var shazamID: String?
    var matchedAt: Date
    var enrichmentData: EnrichmentData?
    // Elapsed seconds from listening start to match found (streaming)
    var timeToMatchSeconds: Double?
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String? = nil,
        albumArtURL: String? = nil,
        appleMusicID: String? = nil,
        shazamID: String? = nil,
        matchedAt: Date = Date(),
        enrichmentData: EnrichmentData? = nil,
        timeToMatchSeconds: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtURL = albumArtURL
        self.appleMusicID = appleMusicID
        self.shazamID = shazamID
        self.matchedAt = matchedAt
        self.enrichmentData = enrichmentData
        self.timeToMatchSeconds = timeToMatchSeconds
    }
    
    // Legacy init for backward compatibility
    init(
        title: String,
        artist: String,
        artworkURL: String? = nil,
        appleMusicID: String? = nil,
        enrichmentData: EnrichmentData? = nil,
        timeToMatchSeconds: Double? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.album = nil
        self.albumArtURL = artworkURL
        self.appleMusicID = appleMusicID
        self.shazamID = nil
        self.matchedAt = Date()
        self.enrichmentData = enrichmentData
        self.timeToMatchSeconds = timeToMatchSeconds
    }
}

extension SongMatch {
    var displayTitle: String {
        "\(title) - \(artist)"
    }
    
    var hasEnrichment: Bool {
        enrichmentData != nil
    }
    
    var formattedMatchDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: matchedAt)
    }

    var formattedTimeToMatch: String? {
        guard let seconds = timeToMatchSeconds else { return nil }
        return String(format: "%.2fs", seconds)
    }
}