import XCTest
@testable import TrackNerd

final class EnrichmentDataTests: XCTestCase {
    
    func testEnrichmentDataInitialization() {
        let enrichment = EnrichmentData(
            artistBio: "Famous artist",
            songTrivia: "Hit song from 1985",
            funFact: "Recorded in one take",
            relatedArtists: ["Artist 1", "Artist 2"],
            relatedSongs: ["Song 1", "Song 2"],
            genres: ["Rock", "Pop"],
            releaseYear: 1985,
            albumName: "Test Album"
        )
        
        XCTAssertEqual(enrichment.artistBio, "Famous artist")
        XCTAssertEqual(enrichment.songTrivia, "Hit song from 1985")
        XCTAssertEqual(enrichment.funFact, "Recorded in one take")
        XCTAssertEqual(enrichment.relatedArtists.count, 2)
        XCTAssertEqual(enrichment.relatedSongs.count, 2)
        XCTAssertEqual(enrichment.genres.count, 2)
        XCTAssertEqual(enrichment.releaseYear, 1985)
        XCTAssertEqual(enrichment.albumName, "Test Album")
        XCTAssertNotNil(enrichment.enrichedAt)
    }
    
    func testHasArtistInfo() {
        let enrichmentWithBio = EnrichmentData(artistBio: "Test bio")
        XCTAssertTrue(enrichmentWithBio.hasArtistInfo)
        
        let enrichmentWithGenres = EnrichmentData(genres: ["Rock"])
        XCTAssertTrue(enrichmentWithGenres.hasArtistInfo)
        
        let enrichmentWithRelated = EnrichmentData(relatedArtists: ["Artist"])
        XCTAssertTrue(enrichmentWithRelated.hasArtistInfo)
        
        let enrichmentEmpty = EnrichmentData()
        XCTAssertFalse(enrichmentEmpty.hasArtistInfo)
    }
    
    func testHasSongInfo() {
        let enrichmentWithTrivia = EnrichmentData(songTrivia: "Test trivia")
        XCTAssertTrue(enrichmentWithTrivia.hasSongInfo)
        
        let enrichmentWithFact = EnrichmentData(funFact: "Test fact")
        XCTAssertTrue(enrichmentWithFact.hasSongInfo)
        
        let enrichmentWithAlbum = EnrichmentData(albumName: "Test Album")
        XCTAssertTrue(enrichmentWithAlbum.hasSongInfo)
        
        let enrichmentWithRelatedSongs = EnrichmentData(relatedSongs: ["Song"])
        XCTAssertTrue(enrichmentWithRelatedSongs.hasSongInfo)
        
        let enrichmentEmpty = EnrichmentData()
        XCTAssertFalse(enrichmentEmpty.hasSongInfo)
    }
    
    func testIsEmpty() {
        let enrichmentEmpty = EnrichmentData()
        XCTAssertTrue(enrichmentEmpty.isEmpty)
        
        let enrichmentWithData = EnrichmentData(artistBio: "Test")
        XCTAssertFalse(enrichmentWithData.isEmpty)
    }
    
    func testFormattedReleaseInfo() {
        let enrichmentWithBoth = EnrichmentData(releaseYear: 1985, albumName: "Test Album")
        XCTAssertEqual(enrichmentWithBoth.formattedReleaseInfo, "Test Album (1985)")
        
        let enrichmentYearOnly = EnrichmentData(releaseYear: 1985)
        XCTAssertEqual(enrichmentYearOnly.formattedReleaseInfo, "1985")
        
        let enrichmentAlbumOnly = EnrichmentData(albumName: "Test Album")
        XCTAssertEqual(enrichmentAlbumOnly.formattedReleaseInfo, "Test Album")
        
        let enrichmentEmpty = EnrichmentData()
        XCTAssertNil(enrichmentEmpty.formattedReleaseInfo)
    }
    
    func testCodableConformance() throws {
        let original = EnrichmentData(
            artistBio: "Test bio",
            songTrivia: "Test trivia",
            genres: ["Rock", "Pop"],
            releaseYear: 1985
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EnrichmentData.self, from: encoded)
        
        XCTAssertEqual(decoded.artistBio, original.artistBio)
        XCTAssertEqual(decoded.songTrivia, original.songTrivia)
        XCTAssertEqual(decoded.genres, original.genres)
        XCTAssertEqual(decoded.releaseYear, original.releaseYear)
    }
    
    func testEnrichedAtIsRecent() {
        let enrichment = EnrichmentData()
        let timeDifference = Date().timeIntervalSince(enrichment.enrichedAt)
        
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    // MARK: - Fun Facts Tests
    
    func testFunFactsCategorization() {
        let funFacts = [
            "lore": "Artist lore fact",
            "bts": "Behind the scenes fact", 
            "activity": "Activity fact",
            "surprise": "Surprise fact"
        ]
        
        let enrichment = EnrichmentData(funFacts: funFacts)
        
        XCTAssertEqual(enrichment.loreFact, "Artist lore fact")
        XCTAssertEqual(enrichment.btsFact, "Behind the scenes fact")
        XCTAssertEqual(enrichment.activityFact, "Activity fact")
        XCTAssertEqual(enrichment.surpriseFact, "Surprise fact")
    }
    
    func testHasAnyFunFacts() {
        let enrichmentWithLegacy = EnrichmentData(funFact: "Legacy fact")
        XCTAssertTrue(enrichmentWithLegacy.hasAnyFunFacts)
        
        let enrichmentWithCategorized = EnrichmentData(funFacts: ["lore": "Test fact"])
        XCTAssertTrue(enrichmentWithCategorized.hasAnyFunFacts)
        
        let enrichmentEmpty = EnrichmentData()
        XCTAssertFalse(enrichmentEmpty.hasAnyFunFacts)
    }
    
    func testAvailableFunFactTypes() {
        let funFacts = [
            "surprise": "Surprise fact",
            "lore": "Lore fact",
            "bts": "BTS fact"
        ]
        
        let enrichment = EnrichmentData(funFacts: funFacts)
        let types = enrichment.availableFunFactTypes
        
        XCTAssertEqual(types.count, 3)
        XCTAssertTrue(types.contains("lore"))
        XCTAssertTrue(types.contains("bts"))
        XCTAssertTrue(types.contains("surprise"))
        // Should be sorted
        XCTAssertEqual(types, ["bts", "lore", "surprise"])
    }
    
    func testFunFactForType() {
        let funFacts = ["lore": "Test lore fact", "activity": "Test activity fact"]
        let enrichment = EnrichmentData(funFacts: funFacts)
        
        XCTAssertEqual(enrichment.funFact(for: "lore"), "Test lore fact")
        XCTAssertEqual(enrichment.funFact(for: "activity"), "Test activity fact")
        XCTAssertNil(enrichment.funFact(for: "bts"))
        XCTAssertNil(enrichment.funFact(for: "surprise"))
    }
    
    func testHasSongInfoWithFunFacts() {
        let enrichmentWithFunFacts = EnrichmentData(funFacts: ["lore": "Test fact"])
        XCTAssertTrue(enrichmentWithFunFacts.hasSongInfo)
        
        let enrichmentWithBoth = EnrichmentData(funFact: "Legacy", funFacts: ["lore": "New"])
        XCTAssertTrue(enrichmentWithBoth.hasSongInfo)
    }
    
    func testIsEmptyWithFunFacts() {
        let enrichmentWithFunFacts = EnrichmentData(funFacts: ["lore": "Test fact"])
        XCTAssertFalse(enrichmentWithFunFacts.isEmpty)
        
        let enrichmentEmpty = EnrichmentData(funFacts: [:])
        XCTAssertTrue(enrichmentEmpty.isEmpty)
    }
    
    // MARK: - Error Tracking Tests
    
    func testErrorTrackingInitialization() {
        let bioError = EnrichmentError.networkError
        let funFactErrors = [
            "lore": EnrichmentError.artistNotFound,
            "bts": EnrichmentError.rateLimited
        ]
        
        let enrichment = EnrichmentData(
            artistBio: nil,
            bioError: bioError,
            funFactErrors: funFactErrors
        )
        
        XCTAssertEqual(enrichment.bioError, .networkError)
        XCTAssertEqual(enrichment.funFactErrors["lore"], .artistNotFound)
        XCTAssertEqual(enrichment.funFactErrors["bts"], .rateLimited)
        XCTAssertEqual(enrichment.funFactErrors.count, 2)
    }
    
    func testErrorTrackingWithContent() {
        let enrichment = EnrichmentData(
            artistBio: "Test bio",
            funFacts: ["lore": "Test lore"],
            bioError: nil,
            funFactErrors: ["bts": .timeout, "activity": .serverError]
        )
        
        // Content should be present
        XCTAssertEqual(enrichment.artistBio, "Test bio")
        XCTAssertEqual(enrichment.loreFact, "Test lore")
        
        // Errors should track failed content types
        XCTAssertNil(enrichment.bioError)
        XCTAssertEqual(enrichment.funFactErrors["bts"], .timeout)
        XCTAssertEqual(enrichment.funFactErrors["activity"], .serverError)
        XCTAssertNil(enrichment.funFactErrors["lore"]) // No error for successful lore
    }
    
    func testCodableConformanceWithErrors() throws {
        let original = EnrichmentData(
            artistBio: nil,
            funFacts: ["lore": "Test lore"],
            bioError: .artistNotFound,
            funFactErrors: [
                "bts": .rateLimited,
                "activity": .networkError
            ]
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EnrichmentData.self, from: encoded)
        
        XCTAssertEqual(decoded.bioError, original.bioError)
        XCTAssertEqual(decoded.funFactErrors.count, original.funFactErrors.count)
        XCTAssertEqual(decoded.funFactErrors["bts"], .rateLimited)
        XCTAssertEqual(decoded.funFactErrors["activity"], .networkError)
        XCTAssertEqual(decoded.funFacts["lore"], "Test lore")
    }
}
