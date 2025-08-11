import Foundation
import SwiftData

/// Cache key structure for enrichment data
struct EnrichmentCacheKey: Hashable {
    let artistId: String
    let type: EnrichmentDataType
    
    enum EnrichmentDataType: Hashable {
        case bio
        case funFact(FunFactType)
    }
}

/// SwiftData-powered persistent cache for enrichment data with expiration support
@MainActor
class EnrichmentCache {
    static let shared = EnrichmentCache()
    
    private var modelContext: ModelContext {
        Container.shared.modelContainer.mainContext
    }
    
    // MARK: - Configuration
    
    /// Default cache expiration time (24 hours)
    private let defaultExpirationInterval: TimeInterval = 24 * 60 * 60
    
    /// Maximum cache size (200 items)
    private let maxCacheSize = 200
    
    private init() {
        // Clear expired items periodically
        startPeriodicCleanup()
    }
    
    // MARK: - Cache Operations
    
    /// Store enrichment data in cache
    func store(_ data: String, for key: EnrichmentCacheKey, expirationInterval: TimeInterval? = nil) {
        let expiration = expirationInterval ?? defaultExpirationInterval
        let cacheKey = EnrichmentCacheEntry.generateCacheKey(for: key)
        
        do {
            // Remove existing entry if it exists
            let existingDescriptor = FetchDescriptor<EnrichmentCacheEntry>(
                predicate: #Predicate { $0.cacheKey == cacheKey }
            )
            let existingEntries = try modelContext.fetch(existingDescriptor)
            for entry in existingEntries {
                modelContext.delete(entry)
            }
            
            // Create new entry
            let newEntry = EnrichmentCacheEntry(
                cacheKey: cacheKey,
                data: data,
                timestamp: Date(),
                expirationInterval: expiration
            )
            modelContext.insert(newEntry)
            
            try modelContext.save()
            
            logWithTimestamp("Stored \(key.type) for artist \(key.artistId) in persistent cache (expires in \(Int(expiration/60/60))h)")
            
            // Maintain cache size limit
            trimCacheIfNeeded()
            
        } catch {
            logWithTimestamp("Failed to store cache entry: \(error)")
        }
    }
    
    /// Retrieve enrichment data from cache
    func retrieve(for key: EnrichmentCacheKey) -> String? {
        let cacheKey = EnrichmentCacheEntry.generateCacheKey(for: key)
        
        do {
            let descriptor = FetchDescriptor<EnrichmentCacheEntry>(
                predicate: #Predicate { $0.cacheKey == cacheKey }
            )
            let entries = try modelContext.fetch(descriptor)
            
            guard let entry = entries.first else {
                logWithTimestamp("Cache MISS for \(key.type) - artist \(key.artistId)")
                return nil
            }
            
            if entry.isExpired {
                modelContext.delete(entry)
                try modelContext.save()
                logWithTimestamp("Cache EXPIRED for \(key.type) - artist \(key.artistId)")
                return nil
            }
            
            logWithTimestamp("Cache HIT for \(key.type) - artist \(key.artistId)")
            return entry.data
            
        } catch {
            logWithTimestamp("Failed to retrieve cache entry: \(error)")
            return nil
        }
    }
    
    /// Remove specific item from cache
    func remove(for key: EnrichmentCacheKey) {
        let cacheKey = EnrichmentCacheEntry.generateCacheKey(for: key)
        
        do {
            let descriptor = FetchDescriptor<EnrichmentCacheEntry>(
                predicate: #Predicate { $0.cacheKey == cacheKey }
            )
            let entries = try modelContext.fetch(descriptor)
            
            for entry in entries {
                modelContext.delete(entry)
            }
            
            try modelContext.save()
            logWithTimestamp("Removed \(key.type) for artist \(key.artistId) from persistent cache")
            
        } catch {
            logWithTimestamp("Failed to remove cache entry: \(error)")
        }
    }
    
    /// Clear all cached data
    func clearAll() {
        do {
            let descriptor = FetchDescriptor<EnrichmentCacheEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            for entry in allEntries {
                modelContext.delete(entry)
            }
            
            try modelContext.save()
            logWithTimestamp("Cleared all persistent enrichment cache (\(allEntries.count) entries)")
            
        } catch {
            logWithTimestamp("Failed to clear all cache entries: \(error)")
        }
    }
    
    /// Clear expired items from cache
    func clearExpired() {
        do {
            let descriptor = FetchDescriptor<EnrichmentCacheEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            var expiredCount = 0
            for entry in allEntries {
                if entry.isExpired {
                    modelContext.delete(entry)
                    expiredCount += 1
                }
            }
            
            if expiredCount > 0 {
                try modelContext.save()
            }
            
            logWithTimestamp("Expired cache cleanup completed - removed \(expiredCount) entries")
            
        } catch {
            logWithTimestamp("Failed to clear expired cache entries: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func trimCacheIfNeeded() {
        do {
            let descriptor = FetchDescriptor<EnrichmentCacheEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let allEntries = try modelContext.fetch(descriptor)
            
            if allEntries.count > maxCacheSize {
                let entriesToDelete = allEntries.dropFirst(maxCacheSize)
                for entry in entriesToDelete {
                    modelContext.delete(entry)
                }
                
                try modelContext.save()
                logWithTimestamp("Trimmed cache to \(maxCacheSize) entries (removed \(entriesToDelete.count) oldest entries)")
            }
            
        } catch {
            logWithTimestamp("Failed to trim cache: \(error)")
        }
    }
    
    private func startPeriodicCleanup() {
        // Clean up expired items every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.clearExpired()
            }
        }
    }
    
    private func logWithTimestamp(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp)] EnrichmentCache: \(message)")
    }
    
    // MARK: - Cache Statistics
    
    /// Get current cache statistics
    func getCacheStats() -> (totalEntries: Int, expiredEntries: Int) {
        do {
            let descriptor = FetchDescriptor<EnrichmentCacheEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            
            let expiredCount = allEntries.filter { $0.isExpired }.count
            
            return (totalEntries: allEntries.count, expiredEntries: expiredCount)
            
        } catch {
            logWithTimestamp("Failed to get cache stats: \(error)")
            return (totalEntries: 0, expiredEntries: 0)
        }
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

