import Foundation
import SwiftData

@Model
final class EnrichmentCacheEntry {
    var cacheKey: String
    var data: String
    var timestamp: Date
    var expirationInterval: TimeInterval
    
    init(cacheKey: String, data: String, timestamp: Date, expirationInterval: TimeInterval) {
        self.cacheKey = cacheKey
        self.data = data
        self.timestamp = timestamp
        self.expirationInterval = expirationInterval
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationInterval
    }
}

extension EnrichmentCacheEntry {
    static func generateCacheKey(for key: EnrichmentCacheKey) -> String {
        switch key.type {
        case .bio:
            return "bio_\(key.artistId)"
        case .funFact(let funFactType):
            return "funfact_\(funFactType.rawValue)_\(key.artistId)"
        }
    }
}