import XCTest
import SwiftData
@testable import TrackNerd

@MainActor
final class SwiftDataPersistenceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var storageService: StorageService!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([SongMatch.self, EnrichmentData.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            storageService = StorageService(modelContext: modelContainer.mainContext)
        } catch {
            XCTFail("Failed to create test model container: \(error)")
        }
    }
    
    override func tearDown() {
        storageService = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Basic CRUD Operations
    
    func testSaveAndLoadSongMatch() async {
        let songMatch = SongMatch(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album"
        )
        
        // Test saving
        let saveResult = await storageService.save(songMatch)
        switch saveResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to save song match: \(error)")
        }
        
        // Test loading
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 1)
            let loadedMatch = matches.first!
            XCTAssertEqual(loadedMatch.title, "Test Song")
            XCTAssertEqual(loadedMatch.artist, "Test Artist")
            XCTAssertEqual(loadedMatch.album, "Test Album")
        case .failure(let error):
            XCTFail("Failed to load matches: \(error)")
        }
    }
    
    func testSaveAndLoadSongMatchWithEnrichment() async {
        let enrichmentData = EnrichmentData(
            artistBio: "Test bio",
            funFacts: ["lore": "Test lore fact", "bts": "Test BTS fact"],
            genres: ["Rock", "Pop"]
        )
        
        let songMatch = SongMatch(
            title: "Enriched Song",
            artist: "Enriched Artist",
            enrichmentData: enrichmentData
        )
        
        // Test saving match with enrichment
        let saveResult = await storageService.save(songMatch)
        switch saveResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to save enriched song match: \(error)")
        }
        
        // Test loading and verifying enrichment data
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 1)
            let loadedMatch = matches.first!
            
            XCTAssertEqual(loadedMatch.title, "Enriched Song")
            XCTAssertEqual(loadedMatch.artist, "Enriched Artist")
            
            // Verify enrichment data
            let loadedEnrichment = loadedMatch.enrichmentData!
            XCTAssertEqual(loadedEnrichment.artistBio, "Test bio")
            XCTAssertEqual(loadedEnrichment.loreFact, "Test lore fact")
            XCTAssertEqual(loadedEnrichment.btsFact, "Test BTS fact")
            XCTAssertEqual(loadedEnrichment.genres, ["Rock", "Pop"])
            
        case .failure(let error):
            XCTFail("Failed to load enriched matches: \(error)")
        }
    }
    
    func testDeleteSongMatch() async {
        let songMatch = SongMatch(title: "Delete Me", artist: "Delete Artist")
        
        // Save the match
        _ = await storageService.save(songMatch)
        
        // Verify it's saved
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 1)
        case .failure(let error):
            XCTFail("Failed to load matches: \(error)")
            return
        }
        
        // Delete the match
        let deleteResult = await storageService.delete(songMatch)
        switch deleteResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to delete match: \(error)")
        }
        
        // Verify it's deleted
        let loadAfterDeleteResult = await storageService.loadMatches()
        switch loadAfterDeleteResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 0)
        case .failure(let error):
            XCTFail("Failed to load matches after delete: \(error)")
        }
    }
    
    // MARK: - Multiple Matches & Sorting
    
    func testMultipleMatchesSortedByDate() async {
        let match1 = SongMatch(title: "First Song", artist: "First Artist")
        let match2 = SongMatch(title: "Second Song", artist: "Second Artist")
        let match3 = SongMatch(title: "Third Song", artist: "Third Artist")
        
        // Save matches with slight delays to ensure different timestamps
        _ = await storageService.save(match1)
        do { try await Task.sleep(nanoseconds: 10_000_000) } catch { } // 10ms
        _ = await storageService.save(match2)
        do { try await Task.sleep(nanoseconds: 10_000_000) } catch { } // 10ms  
        _ = await storageService.save(match3)
        
        // Load and verify sorting (most recent first)
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 3)
            XCTAssertEqual(matches[0].title, "Third Song") // Most recent
            XCTAssertEqual(matches[1].title, "Second Song")
            XCTAssertEqual(matches[2].title, "First Song") // Oldest
        case .failure(let error):
            XCTFail("Failed to load matches: \(error)")
        }
    }
    
    // MARK: - Enrichment Error Persistence
    
    func testPersistenceOfEnrichmentErrors() async {
        let enrichmentData = EnrichmentData(
            artistBio: nil,
            bioError: .networkError,
            funFactErrors: [
                "lore": .artistNotFound,
                "bts": .rateLimited,
                "activity": .timeout
            ]
        )
        
        let songMatch = SongMatch(
            title: "Error Test Song",
            artist: "Error Artist",
            enrichmentData: enrichmentData
        )
        
        // Save and load
        _ = await storageService.save(songMatch)
        
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 1)
            let loadedMatch = matches.first!
            let loadedEnrichment = loadedMatch.enrichmentData!
            
            // Verify error data is preserved
            XCTAssertEqual(loadedEnrichment.bioError, .networkError)
            XCTAssertEqual(loadedEnrichment.funFactErrors["lore"], .artistNotFound)
            XCTAssertEqual(loadedEnrichment.funFactErrors["bts"], .rateLimited)
            XCTAssertEqual(loadedEnrichment.funFactErrors["activity"], .timeout)
            XCTAssertEqual(loadedEnrichment.funFactErrors.count, 3)
            
        case .failure(let error):
            XCTFail("Failed to load matches with errors: \(error)")
        }
    }
    
    // MARK: - Large Dataset Performance
    
    func testLargeDatasetPerformance() async {
        let matches = (1...100).map { index in
            SongMatch(
                title: "Song \(index)",
                artist: "Artist \(index % 10)", // Some duplicate artists
                album: "Album \(index % 5)", // Some duplicate albums
                enrichmentData: EnrichmentData(
                    artistBio: "Bio for artist \(index % 10)",
                    funFacts: [
                        "lore": "Lore fact \(index)",
                        "bts": "BTS fact \(index)"
                    ]
                )
            )
        }
        
        // Measure save time
        let saveStart = Date()
        for match in matches {
            let result = await storageService.save(match)
            if case .failure(let error) = result {
                XCTFail("Failed to save match: \(error)")
                return
            }
        }
        let saveTime = Date().timeIntervalSince(saveStart)
        
        // Measure load time
        let loadStart = Date()
        let loadResult = await storageService.loadMatches()
        let loadTime = Date().timeIntervalSince(loadStart)
        
        switch loadResult {
        case .success(let loadedMatches):
            XCTAssertEqual(loadedMatches.count, 100)
            
            // Verify sorting is maintained
            for i in 1..<loadedMatches.count {
                XCTAssertGreaterThanOrEqual(
                    loadedMatches[i-1].matchedAt,
                    loadedMatches[i].matchedAt,
                    "Matches should be sorted by date (newest first)"
                )
            }
            
            // Performance assertions (generous limits for CI)
            XCTAssertLessThan(saveTime, 10.0, "Saving 100 matches should take less than 10 seconds")
            XCTAssertLessThan(loadTime, 2.0, "Loading 100 matches should take less than 2 seconds")
            
        case .failure(let error):
            XCTFail("Failed to load large dataset: \(error)")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityAfterAppRestart() async {
        // This test simulates app restart by creating a new storage service instance
        // with the same model container
        
        let originalMatch = SongMatch(
            title: "Persistent Song",
            artist: "Persistent Artist",
            enrichmentData: EnrichmentData(
                artistBio: "Original bio",
                funFacts: ["lore": "Original lore"]
            )
        )
        
        // Save with original service
        _ = await storageService.save(originalMatch)
        
        // Create new storage service (simulating app restart)
        let newStorageService = StorageService(modelContext: modelContainer.mainContext)
        
        // Load with new service
        let loadResult = await newStorageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 1)
            let loadedMatch = matches.first!
            
            XCTAssertEqual(loadedMatch.title, "Persistent Song")
            XCTAssertEqual(loadedMatch.artist, "Persistent Artist")
            XCTAssertEqual(loadedMatch.enrichmentData?.artistBio, "Original bio")
            XCTAssertEqual(loadedMatch.enrichmentData?.loreFact, "Original lore")
            
        case .failure(let error):
            XCTFail("Failed to maintain data integrity across restart: \(error)")
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyDatabase() async {
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 0)
        case .failure(let error):
            XCTFail("Loading empty database should succeed: \(error)")
        }
    }
    
    func testSaveMatchWithMinimalData() async {
        let minimalMatch = SongMatch(title: "Minimal", artist: "Minimal Artist")
        
        let saveResult = await storageService.save(minimalMatch)
        switch saveResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to save minimal match: \(error)")
        }
        
        let loadResult = await storageService.loadMatches()
        switch loadResult {
        case .success(let matches):
            XCTAssertEqual(matches.count, 1)
            let loadedMatch = matches.first!
            XCTAssertEqual(loadedMatch.title, "Minimal")
            XCTAssertEqual(loadedMatch.artist, "Minimal Artist")
            XCTAssertNil(loadedMatch.album)
            XCTAssertNil(loadedMatch.enrichmentData)
        case .failure(let error):
            XCTFail("Failed to load minimal match: \(error)")
        }
    }
}