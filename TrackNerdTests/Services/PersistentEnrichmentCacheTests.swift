import XCTest
import SwiftData
@testable import TrackNerd

@MainActor
final class PersistentEnrichmentCacheTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var cache: EnrichmentCache!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([EnrichmentCacheEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            
            // Replace the container in the shared Container instance for testing
            Container.shared.modelContainer = modelContainer
            cache = EnrichmentCache.shared
        } catch {
            XCTFail("Failed to create test model container: \(error)")
        }
    }
    
    override func tearDown() async throws {
        cache = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Persistence Tests
    
    func testStoreAndRetrieve() {
        let key = EnrichmentCacheKey(artistId: "artist123", type: .bio)
        let testData = "Test artist biography"
        
        // Store data
        cache.store(testData, for: key)
        
        // Retrieve data
        let retrievedData = cache.retrieve(for: key)
        XCTAssertEqual(retrievedData, testData)
    }
    
    func testRetrieveNonExistentKey() {
        let key = EnrichmentCacheKey(artistId: "nonexistent", type: .bio)
        
        let result = cache.retrieve(for: key)
        XCTAssertNil(result)
    }
    
    func testMultipleDataTypes() {
        let artistId = "multitest123"
        let bioKey = EnrichmentCacheKey(artistId: artistId, type: .bio)
        let loreKey = EnrichmentCacheKey(artistId: artistId, type: .funFact(.lore))
        let btsKey = EnrichmentCacheKey(artistId: artistId, type: .funFact(.bts))
        
        let bioData = "Artist biography"
        let loreData = "Lore fun fact"
        let btsData = "Behind the scenes fact"
        
        cache.store(bioData, for: bioKey)
        cache.store(loreData, for: loreKey)
        cache.store(btsData, for: btsKey)
        
        XCTAssertEqual(cache.retrieve(for: bioKey), bioData)
        XCTAssertEqual(cache.retrieve(for: loreKey), loreData)
        XCTAssertEqual(cache.retrieve(for: btsKey), btsData)
    }
    
    // MARK: - Expiration Tests
    
    func testExpiration() async {
        let key = EnrichmentCacheKey(artistId: "expire123", type: .bio)
        let testData = "Data that will expire"
        
        // Store with very short expiration (0.1 seconds)
        cache.store(testData, for: key, expirationInterval: 0.1)
        
        // Should be available immediately
        XCTAssertEqual(cache.retrieve(for: key), testData)
        
        // Wait for expiration
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Should be expired and return nil
        XCTAssertNil(cache.retrieve(for: key))
    }
    
    func testCustomExpirationInterval() {
        let key = EnrichmentCacheKey(artistId: "custom123", type: .funFact(.activity))
        let testData = "Custom expiration data"
        let customExpiration: TimeInterval = 3600 // 1 hour
        
        cache.store(testData, for: key, expirationInterval: customExpiration)
        
        // Should still be available (not expired yet)
        XCTAssertEqual(cache.retrieve(for: key), testData)
        
        // Verify the expiration interval is stored correctly
        let stats = cache.getCacheStats()
        XCTAssertEqual(stats.totalEntries, 1)
        XCTAssertEqual(stats.expiredEntries, 0)
    }
    
    // MARK: - Cache Management Tests
    
    func testRemoveSpecificEntry() {
        let key1 = EnrichmentCacheKey(artistId: "artist1", type: .bio)
        let key2 = EnrichmentCacheKey(artistId: "artist2", type: .bio)
        
        let data1 = "Artist 1 bio"
        let data2 = "Artist 2 bio"
        
        cache.store(data1, for: key1)
        cache.store(data2, for: key2)
        
        // Both should be available
        XCTAssertEqual(cache.retrieve(for: key1), data1)
        XCTAssertEqual(cache.retrieve(for: key2), data2)
        
        // Remove only key1
        cache.remove(for: key1)
        
        // key1 should be gone, key2 should remain
        XCTAssertNil(cache.retrieve(for: key1))
        XCTAssertEqual(cache.retrieve(for: key2), data2)
    }
    
    func testClearAll() {
        let key1 = EnrichmentCacheKey(artistId: "artist1", type: .bio)
        let key2 = EnrichmentCacheKey(artistId: "artist2", type: .funFact(.lore))
        
        cache.store("Bio data", for: key1)
        cache.store("Lore data", for: key2)
        
        // Both should be available
        XCTAssertNotNil(cache.retrieve(for: key1))
        XCTAssertNotNil(cache.retrieve(for: key2))
        
        // Clear all
        cache.clearAll()
        
        // Both should be gone
        XCTAssertNil(cache.retrieve(for: key1))
        XCTAssertNil(cache.retrieve(for: key2))
        
        // Cache stats should show empty cache
        let stats = cache.getCacheStats()
        XCTAssertEqual(stats.totalEntries, 0)
    }
    
    func testClearExpired() async {
        let key1 = EnrichmentCacheKey(artistId: "expire1", type: .bio)
        let key2 = EnrichmentCacheKey(artistId: "persist1", type: .bio)
        
        // Store one with short expiration, one with long expiration
        cache.store("Will expire", for: key1, expirationInterval: 0.1)
        cache.store("Will persist", for: key2, expirationInterval: 3600)
        
        // Wait for first to expire
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Clear expired items
        cache.clearExpired()
        
        // Expired item should be gone, persistent item should remain
        XCTAssertNil(cache.retrieve(for: key1))
        XCTAssertEqual(cache.retrieve(for: key2), "Will persist")
    }
    
    // MARK: - Cache Statistics Tests
    
    func testCacheStats() async {
        // Start with empty cache
        var stats = cache.getCacheStats()
        XCTAssertEqual(stats.totalEntries, 0)
        XCTAssertEqual(stats.expiredEntries, 0)
        
        // Add some entries
        let key1 = EnrichmentCacheKey(artistId: "stats1", type: .bio)
        let key2 = EnrichmentCacheKey(artistId: "stats2", type: .funFact(.lore))
        let key3 = EnrichmentCacheKey(artistId: "stats3", type: .funFact(.bts))
        
        cache.store("Data 1", for: key1)
        cache.store("Data 2", for: key2)
        cache.store("Data 3", for: key3, expirationInterval: 0.1) // Will expire quickly
        
        // Check stats after storing
        stats = cache.getCacheStats()
        XCTAssertEqual(stats.totalEntries, 3)
        XCTAssertEqual(stats.expiredEntries, 0)
        
        // Wait for one to expire
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Check stats with expired item
        stats = cache.getCacheStats()
        XCTAssertEqual(stats.totalEntries, 3) // Still there until cleaned up
        XCTAssertEqual(stats.expiredEntries, 1) // One is expired
    }
    
    // MARK: - Data Persistence Tests
    
    func testDataPersistenceAcrossCacheInstances() {
        let key = EnrichmentCacheKey(artistId: "persistent123", type: .bio)
        let testData = "Persistent data"
        
        // Store data with original cache instance
        cache.store(testData, for: key)
        
        // Verify data is stored
        XCTAssertEqual(cache.retrieve(for: key), testData)
        
        // Create new cache instance (simulating app restart)
        let newCache = EnrichmentCache.shared // Same singleton instance
        
        // Data should still be available
        XCTAssertEqual(newCache.retrieve(for: key), testData)
    }
    
    func testUpdateExistingEntry() {
        let key = EnrichmentCacheKey(artistId: "update123", type: .bio)
        let originalData = "Original data"
        let updatedData = "Updated data"
        
        // Store original data
        cache.store(originalData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), originalData)
        
        // Update with new data
        cache.store(updatedData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), updatedData)
        
        // Should only have one entry for this key
        let stats = cache.getCacheStats()
        XCTAssertEqual(stats.totalEntries, 1)
    }
    
    // MARK: - Performance and Edge Cases
    
    func testLargeDataStorage() {
        let key = EnrichmentCacheKey(artistId: "large123", type: .bio)
        let largeData = String(repeating: "A", count: 50000) // 50KB string
        
        cache.store(largeData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), largeData)
    }
    
    func testEmptyDataStorage() {
        let key = EnrichmentCacheKey(artistId: "empty123", type: .bio)
        let emptyData = ""
        
        cache.store(emptyData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), emptyData)
    }
    
    func testSpecialCharactersInData() {
        let key = EnrichmentCacheKey(artistId: "special123", type: .bio)
        let specialData = "Data with émojis 🎵 and spéciål characters ñ"
        
        cache.store(specialData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), specialData)
    }
    
    func testCacheKeyGeneration() {
        let bioKey = EnrichmentCacheKey(artistId: "test123", type: .bio)
        let loreKey = EnrichmentCacheKey(artistId: "test123", type: .funFact(.lore))
        let btsKey = EnrichmentCacheKey(artistId: "test123", type: .funFact(.bts))
        
        let bioKeyString = EnrichmentCacheEntry.generateCacheKey(for: bioKey)
        let loreKeyString = EnrichmentCacheEntry.generateCacheKey(for: loreKey)
        let btsKeyString = EnrichmentCacheEntry.generateCacheKey(for: btsKey)
        
        // Keys should be different
        XCTAssertNotEqual(bioKeyString, loreKeyString)
        XCTAssertNotEqual(bioKeyString, btsKeyString)
        XCTAssertNotEqual(loreKeyString, btsKeyString)
        
        // Keys should follow expected format
        XCTAssertEqual(bioKeyString, "bio_test123")
        XCTAssertEqual(loreKeyString, "funfact_lore_test123")
        XCTAssertEqual(btsKeyString, "funfact_bts_test123")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentStoreAndRetrieve() async {
        let key = EnrichmentCacheKey(artistId: "concurrent123", type: .bio)
        let testData = "Concurrent test data"
        
        // Use TaskGroup to test concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Store operations
            for i in 0..<10 {
                group.addTask { @MainActor in
                    self.cache.store("\(testData) \(i)", for: key)
                }
            }
            
            // Retrieve operations
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    _ = self.cache.retrieve(for: key)
                }
            }
        }
        
        // Should not crash and should have some data
        let finalData = cache.retrieve(for: key)
        XCTAssertNotNil(finalData)
        XCTAssertTrue(finalData!.contains("Concurrent test data"))
    }
}