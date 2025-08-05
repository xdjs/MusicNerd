import Foundation
import SwiftData

@Model
final class SongMatch {
    var id: UUID
    var title: String
    var artist: String
    var artworkURL: String?
    var appleMusicID: String?
    var matchedAt: Date
    var enrichmentData: EnrichmentData?
    
    init(
        title: String,
        artist: String,
        artworkURL: String? = nil,
        appleMusicID: String? = nil,
        enrichmentData: EnrichmentData? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.appleMusicID = appleMusicID
        self.matchedAt = Date()
        self.enrichmentData = enrichmentData
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
}