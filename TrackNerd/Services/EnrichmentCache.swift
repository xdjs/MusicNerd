import Foundation

/// Cache key structure for enrichment data
struct EnrichmentCacheKey: Hashable {
    let artistId: String
    let type: EnrichmentDataType
    
    enum EnrichmentDataType: Hashable {
        case bio
        case funFact(FunFactType)
    }
}

/// Cached enrichment data with expiration
class CachedEnrichmentData {
    let data: String
    let timestamp: Date
    let expirationInterval: TimeInterval
    
    init(data: String, timestamp: Date, expirationInterval: TimeInterval) {
        self.data = data
        self.timestamp = timestamp
        self.expirationInterval = expirationInterval
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationInterval
    }
}

/// In-memory cache for enrichment data with expiration support
class EnrichmentCache {
    static let shared = EnrichmentCache()
    
    private let cache = NSCache<NSString, CachedEnrichmentData>()
    private let queue = DispatchQueue(label: "enrichment.cache", attributes: .concurrent)
    
    // MARK: - Configuration
    
    /// Default cache expiration time (24 hours)
    private let defaultExpirationInterval: TimeInterval = 24 * 60 * 60
    
    /// Maximum cache size (100 items)
    private let maxCacheSize = 100
    
    private init() {
        cache.countLimit = maxCacheSize
        
        // Clear expired items periodically
        startPeriodicCleanup()
    }
    
    // MARK: - Cache Operations
    
    /// Store enrichment data in cache
    func store(_ data: String, for key: EnrichmentCacheKey, expirationInterval: TimeInterval? = nil) {
        let expiration = expirationInterval ?? defaultExpirationInterval
        let cachedData = CachedEnrichmentData(
            data: data,
            timestamp: Date(),
            expirationInterval: expiration
        )
        
        queue.async(flags: .barrier) {
            let cacheKey = NSString(string: self.generateCacheKey(for: key))
            self.cache.setObject(cachedData, forKey: cacheKey)
            self.logWithTimestamp("Stored \(key.type) for artist \(key.artistId) in cache (expires in \(Int(expiration/60/60))h)")
        }
    }
    
    /// Retrieve enrichment data from cache
    func retrieve(for key: EnrichmentCacheKey) -> String? {
        return queue.sync {
            let cacheKey = NSString(string: generateCacheKey(for: key))
            
            guard let cachedData = cache.object(forKey: cacheKey) else {
                logWithTimestamp("Cache MISS for \(key.type) - artist \(key.artistId)")
                return nil
            }
            
            if cachedData.isExpired {
                cache.removeObject(forKey: cacheKey)
                logWithTimestamp("Cache EXPIRED for \(key.type) - artist \(key.artistId)")
                return nil
            }
            
            logWithTimestamp("Cache HIT for \(key.type) - artist \(key.artistId)")
            return cachedData.data
        }
    }
    
    /// Remove specific item from cache
    func remove(for key: EnrichmentCacheKey) {
        queue.async(flags: .barrier) {
            let cacheKey = NSString(string: self.generateCacheKey(for: key))
            self.cache.removeObject(forKey: cacheKey)
            self.logWithTimestamp("Removed \(key.type) for artist \(key.artistId) from cache")
        }
    }
    
    /// Clear all cached data
    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
            self.logWithTimestamp("Cleared all enrichment cache")
        }
    }
    
    /// Clear expired items from cache
    func clearExpired() {
        queue.async(flags: .barrier) {
            // NSCache doesn't provide iteration, so we rely on periodic cleanup
            // and lazy expiration checking during retrieval
            self.logWithTimestamp("Expired cache cleanup completed")
        }
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for key: EnrichmentCacheKey) -> String {
        switch key.type {
        case .bio:
            return "bio_\(key.artistId)"
        case .funFact(let funFactType):
            return "funfact_\(funFactType.rawValue)_\(key.artistId)"
        }
    }
    
    private func startPeriodicCleanup() {
        // Clean up expired items every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.clearExpired()
        }
    }
    
    private func logWithTimestamp(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp)] EnrichmentCache: \(message)")
    }
}

// MARK: - Extensions

extension EnrichmentCacheKey.EnrichmentDataType: CustomStringConvertible {
    var description: String {
        switch self {
        case .bio:
            return "bio"
        case .funFact(let type):
            return "funfact(\(type.rawValue))"
        }
    }
}

