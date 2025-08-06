import XCTest
@testable import TrackNerd

final class SongMatchTests: XCTestCase {
    
    func testSongMatchInitialization() {
        let match = SongMatch(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            artworkURL: "https://example.com/artwork.jpg",
            appleMusicID: "12345"
        )
        
        XCTAssertEqual(match.title, "Bohemian Rhapsody")
        XCTAssertEqual(match.artist, "Queen")
        XCTAssertEqual(match.albumArtURL, "https://example.com/artwork.jpg")
        XCTAssertEqual(match.appleMusicID, "12345")
        XCTAssertNotNil(match.id)
        XCTAssertNil(match.enrichmentData)
        XCTAssertFalse(match.hasEnrichment)
    }
    
    func testSongMatchWithEnrichment() {
        let enrichment = EnrichmentData(
            artistBio: "British rock band",
            songTrivia: "6-minute epic song"
        )
        
        let match = SongMatch(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            enrichmentData: enrichment
        )
        
        XCTAssertTrue(match.hasEnrichment)
        XCTAssertNotNil(match.enrichmentData)
        XCTAssertEqual(match.enrichmentData?.artistBio, "British rock band")
    }
    
    func testDisplayTitle() {
        let match = SongMatch(title: "Test Song", artist: "Test Artist")
        XCTAssertEqual(match.displayTitle, "Test Song - Test Artist")
    }
    
    func testFormattedMatchDate() {
        let match = SongMatch(title: "Test", artist: "Test")
        let formattedDate = match.formattedMatchDate
        
        XCTAssertFalse(formattedDate.isEmpty)
        XCTAssertTrue(formattedDate.contains(":"))
    }
    
    func testMatchedAtIsRecent() {
        let match = SongMatch(title: "Test", artist: "Test")
        let timeDifference = Date().timeIntervalSince(match.matchedAt)
        
        XCTAssertLessThan(timeDifference, 1.0)
    }
}
