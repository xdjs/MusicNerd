import XCTest
@testable import TrackNerd

final class EnrichmentCacheTests: XCTestCase {
    
    var cache: EnrichmentCache!
    
    override func setUp() {
        super.setUp()
        cache = EnrichmentCache.shared
        cache.clearAll()
    }
    
    override func tearDown() {
        cache.clearAll()
        super.tearDown()
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
        let bioKey2 = EnrichmentCacheKey(artistId: "123", type: .bio)
        XCTAssertEqual(bioKey, bioKey2)
    }
    
    // MARK: - Basic Cache Operations
    
    func testStoreAndRetrieve() {
        let key = EnrichmentCacheKey(artistId: "test123", type: .bio)
        let testData = "This is a test bio for the artist."
        
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
    
    func testStoreMultipleItems() {
        let bioKey = EnrichmentCacheKey(artistId: "artist1", type: .bio)
        let loreKey = EnrichmentCacheKey(artistId: "artist1", type: .funFact(.lore))
        let btsKey = EnrichmentCacheKey(artistId: "artist2", type: .funFact(.bts))
        
        let bioData = "Artist biography"
        let loreData = "Artist lore fact"
        let btsData = "Behind the scenes fact"
        
        cache.store(bioData, for: bioKey)
        cache.store(loreData, for: loreKey)
        cache.store(btsData, for: btsKey)
        
        XCTAssertEqual(cache.retrieve(for: bioKey), bioData)
        XCTAssertEqual(cache.retrieve(for: loreKey), loreData)
        XCTAssertEqual(cache.retrieve(for: btsKey), btsData)
    }
    
    // MARK: - Expiration Tests
    
    func testCacheExpiration() {
        let key = EnrichmentCacheKey(artistId: "test123", type: .bio)
        let testData = "This is a test bio."
        
        // Store with very short expiration (0.1 seconds)
        cache.store(testData, for: key, expirationInterval: 0.1)
        
        // Should be available immediately
        XCTAssertEqual(cache.retrieve(for: key), testData)
        
        // Wait for expiration
        let expectation = XCTestExpectation(description: "Wait for cache expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Should be expired now
        XCTAssertNil(cache.retrieve(for: key))
    }
    
    func testCustomExpirationInterval() {
        let key = EnrichmentCacheKey(artistId: "test123", type: .bio)
        let testData = "This is a test bio."
        let customExpiration: TimeInterval = 3600 // 1 hour
        
        cache.store(testData, for: key, expirationInterval: customExpiration)
        
        // Should still be available (not expired yet)
        XCTAssertEqual(cache.retrieve(for: key), testData)
    }
    
    // MARK: - Cache Management Tests
    
    func testRemoveSpecificKey() {
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
    
    // MARK: - Fun Fact Type Tests
    
    func testAllFunFactTypes() {
        let artistId = "testArtist"
        let allTypes: [FunFactType] = [.lore, .bts, .activity, .surprise]
        
        // Store different fun facts
        for (index, type) in allTypes.enumerated() {
            let key = EnrichmentCacheKey(artistId: artistId, type: .funFact(type))
            let data = "Fun fact \(index) for \(type.rawValue)"
            cache.store(data, for: key)
        }
        
        // Retrieve all fun facts
        for (index, type) in allTypes.enumerated() {
            let key = EnrichmentCacheKey(artistId: artistId, type: .funFact(type))
            let expectedData = "Fun fact \(index) for \(type.rawValue)"
            XCTAssertEqual(cache.retrieve(for: key), expectedData)
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() {
        let key = EnrichmentCacheKey(artistId: "concurrent", type: .bio)
        let testData = "Concurrent test data"
        
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 10
        
        // Perform concurrent store/retrieve operations
        for i in 0..<10 {
            DispatchQueue.global(qos: .userInteractive).async {
                if i % 2 == 0 {
                    self.cache.store("\(testData) \(i)", for: key)
                } else {
                    _ = self.cache.retrieve(for: key)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should not crash and should have some data
        let finalData = cache.retrieve(for: key)
        XCTAssertNotNil(finalData)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyArtistId() {
        let key = EnrichmentCacheKey(artistId: "", type: .bio)
        let testData = "Empty artist ID test"
        
        cache.store(testData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), testData)
    }
    
    func testLargeData() {
        let key = EnrichmentCacheKey(artistId: "largeData", type: .bio)
        let largeData = String(repeating: "A", count: 10000) // 10KB string
        
        cache.store(largeData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), largeData)
    }
    
    func testOverwriteExistingKey() {
        let key = EnrichmentCacheKey(artistId: "overwrite", type: .bio)
        let originalData = "Original data"
        let newData = "New data"
        
        cache.store(originalData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), originalData)
        
        cache.store(newData, for: key)
        XCTAssertEqual(cache.retrieve(for: key), newData)
    }
}