import XCTest
import SwiftData
@testable import TrackNerd

@MainActor
final class EnrichmentCacheTests: XCTestCase {
    
    var cache: EnrichmentCache!
    
    override func setUp() async throws {
        try await super.setUp()
        cache = EnrichmentCache.shared
        cache.clearAll() // Start with clean cache for each test
    }
    
    override func tearDown() async throws {
        cache.clearAll() // Clean up after each test
        cache = nil
        try await super.tearDown()
    }
    
    // MARK: - Cache Key Tests
    
    func testCacheKeyGeneration() {
        let bioKey = EnrichmentCacheKey(artistId: "123", type: .bio)
        let loreKey = EnrichmentCacheKey(artistId: "123", type: .funFact(.lore))
        let btsKey = EnrichmentCacheKey(artistId: "456", type: .funFact(.bts))
        
        // Keys should be unique for different types
        XCTAssertNotEqual(bioKey, loreKey)
        XCTAssertNotEqual(loreKey, btsKey)
        
        // Keys should be equal for same data
        let sameBioKey = EnrichmentCacheKey(artistId: "123", type: .bio)
        XCTAssertEqual(bioKey, sameBioKey)
    }
    
    // MARK: - Basic Operations
    
    func testBasicStoreAndRetrieve() {
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
    }
    
    // MARK: - Cache Management
    
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
    }
    
    // MARK: - Performance Tests
    
    func testMultipleEntriesPerformance() {
        let artistTypes: [FunFactType] = [.lore, .bts, .activity, .surprise]
        
        // Store multiple entries for different artists and types
        for i in 1...20 {
            let artistId = "artist\(i)"
            
            // Store bio
            let bioKey = EnrichmentCacheKey(artistId: artistId, type: .bio)
            cache.store("Bio for artist \(i)", for: bioKey)
            
            // Store fun facts
            for type in artistTypes {
                let key = EnrichmentCacheKey(artistId: artistId, type: .funFact(type))
                let data = "Fun fact \(i) for \(type.rawValue)"
                cache.store(data, for: key)
            }
        }
        
        // Verify all data can be retrieved
        for i in 1...20 {
            let artistId = "artist\(i)"
            let bioKey = EnrichmentCacheKey(artistId: artistId, type: .bio)
            let expectedBioData = "Bio for artist \(i)"
            XCTAssertEqual(cache.retrieve(for: bioKey), expectedBioData)
            
            for type in artistTypes {
                let key = EnrichmentCacheKey(artistId: artistId, type: .funFact(type))
                let expectedData = "Fun fact \(i) for \(type.rawValue)"
                XCTAssertEqual(cache.retrieve(for: key), expectedData)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyArtistId() {
        let key = EnrichmentCacheKey(artistId: "", type: .bio)
        let testData = "Empty artist ID test"
        
        cache.store(testData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), testData)
    }
    
    func testLargeDataStorage() {
        let key = EnrichmentCacheKey(artistId: "large123", type: .bio)
        let largeData = String(repeating: "A", count: 10000) // 10KB string
        
        cache.store(largeData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), largeData)
    }
    
    func testDataOverwrite() {
        let key = EnrichmentCacheKey(artistId: "overwrite123", type: .bio)
        let originalData = "Original data"
        let newData = "New data"
        
        cache.store(originalData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), originalData)
        
        cache.store(newData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), newData)
    }
}