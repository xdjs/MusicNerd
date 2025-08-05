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
}
