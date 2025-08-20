import XCTest
@testable import MusicNerd

final class OpenAIServiceIntegrationTests: XCTestCase {
    
    var openAIService: OpenAIService!
    
    override func setUp() {
        super.setUp()
        // Use a mock MusicNerdService to avoid real network calls
        let mockMusicNerdService = MockMusicNerdService()
        openAIService = OpenAIService(musicNerdService: mockMusicNerdService)
    }
    
    override func tearDown() {
        openAIService = nil
        super.tearDown()
    }
    
    func testEnrichSong_WithValidArtist_ShouldReturnEnrichmentData() async {
        let songMatch = SongMatch(
            title: "Test Song",
            artist: "Test Artist"
        )
        
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            XCTAssertNotNil(enrichmentData)
            XCTAssertEqual(enrichmentData.albumName, songMatch.album)
            // Bio and fun fact should be set by mock service
            XCTAssertEqual(enrichmentData.artistBio, "Mock bio for Test Artist")
            XCTAssertEqual(enrichmentData.funFact, "Mock fun fact for Test Artist")
            
        case .failure(let error):
            XCTFail("Expected success but got error: \(error.localizedDescription)")
        }
    }
    
    func testEnrichSong_WithUnknownArtist_ShouldReturnMinimalEnrichmentData() async {
        let songMatch = SongMatch(
            title: "Unknown Song",
            artist: "Unknown Artist"
        )
        
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            XCTAssertNotNil(enrichmentData)
            // Should return minimal enrichment when artist not found
            XCTAssertNil(enrichmentData.artistBio)
            XCTAssertNil(enrichmentData.funFact)
            XCTAssertEqual(enrichmentData.albumName, songMatch.album)
            
        case .failure(let error):
            XCTFail("Expected success (minimal enrichment) but got error: \(error.localizedDescription)")
        }
    }
    
    func testEnrichSong_HandlesEmptyArtistName() async {
        let songMatch = SongMatch(
            title: "Test Song",
            artist: ""
        )
        
        let result = await openAIService.enrichSong(songMatch)
        
        // Should handle gracefully and return minimal enrichment
        switch result {
        case .success(let enrichmentData):
            XCTAssertNotNil(enrichmentData)
            
        case .failure:
            // Also acceptable if it fails gracefully
            break
        }
    }
}

// MARK: - Mock MusicNerdService

class MockMusicNerdService: MusicNerdServiceProtocol {
    
    func searchArtist(name: String) async -> Result<MusicNerdArtist> {
        if name == "Test Artist" {
            let artist = MusicNerdArtist(
                artistId: "1",
                name: "Test Artist",
                spotify: nil,
                instagram: nil,
                x: nil,
                youtube: nil,
                soundcloud: nil,
                bio: nil,
                youtubechannel: nil,
                tiktok: nil,
                bandcamp: nil,
                website: nil
            )
            return .success(artist)
        } else {
            return .failure(.musicNerdError(.artistNotFound))
        }
    }
    
    func getArtistBio(artistId: String) async -> Result<String> {
        if artistId == "1" {
            return .success("Mock bio for Test Artist")
        } else {
            return .failure(.musicNerdError(.noBioAvailable))
        }
    }
    
    func getFunFact(artistId: String, type: FunFactType) async -> Result<String> {
        if artistId == "1" {
            return .success("Mock fun fact for Test Artist")
        } else {
            return .failure(.musicNerdError(.noFunFactAvailable))
        }
    }
}
