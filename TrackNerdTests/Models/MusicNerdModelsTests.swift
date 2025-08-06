import XCTest
@testable import TrackNerd

final class MusicNerdModelsTests: XCTestCase {
    
    // MARK: - SearchArtistsRequest Tests
    
    func testSearchArtistsRequest_Encoding() throws {
        let request = SearchArtistsRequest(query: "Taylor Swift")
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)
        
        // Verify it can be decoded back
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SearchArtistsRequest.self, from: data)
        XCTAssertEqual(decoded.query, "Taylor Swift")
    }
    
    // MARK: - MusicNerdArtist Tests
    
    func testMusicNerdArtist_BasicProperties() {
        let artist = MusicNerdArtist(
            id: "1",
            name: "Test Artist",
            spotify: "test-spotify-id",
            instagram: "test-instagram",
            x: "test-x",
            youtube: "test-youtube",
            soundcloud: "test-soundcloud",
            bio: "Test biography",
            youtubechannel: "test-channel",
            tiktok: "test-tiktok",
            bandcamp: "test-bandcamp",
            website: "https://test.com"
        )
        
        XCTAssertEqual(artist.id, "1")
        XCTAssertEqual(artist.name, "Test Artist")
        XCTAssertEqual(artist.displayName, "Test Artist")
        XCTAssertTrue(artist.hasData)
    }
    
    func testMusicNerdArtist_HasDataWithBio() {
        let artist = MusicNerdArtist(
            id: "1",
            name: "Test Artist",
            spotify: nil,
            instagram: nil,
            x: nil,
            youtube: nil,
            soundcloud: nil,
            bio: "Has bio",
            youtubechannel: nil,
            tiktok: nil,
            bandcamp: nil,
            website: nil
        )
        
        XCTAssertTrue(artist.hasData)
    }
    
    func testMusicNerdArtist_HasDataWithSocialMedia() {
        let artist = MusicNerdArtist(
            id: "1",
            name: "Test Artist",
            spotify: "spotify-id",
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
        
        XCTAssertTrue(artist.hasData)
    }
    
    func testMusicNerdArtist_NoDataWhenEmpty() {
        let artist = MusicNerdArtist(
            id: "1",
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
        
        XCTAssertFalse(artist.hasData)
    }
    
    func testMusicNerdArtist_Codable() throws {
        let originalArtist = MusicNerdArtist(
            id: "123",
            name: "Codable Test",
            spotify: "spotify123",
            instagram: "insta123",
            x: "x123",
            youtube: "yt123",
            soundcloud: "sc123",
            bio: "Test bio",
            youtubechannel: "ytc123",
            tiktok: "tt123",
            bandcamp: "bc123",
            website: "https://example.com"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalArtist)
        
        let decoder = JSONDecoder()
        let decodedArtist = try decoder.decode(MusicNerdArtist.self, from: data)
        
        XCTAssertEqual(decodedArtist.id, originalArtist.id)
        XCTAssertEqual(decodedArtist.name, originalArtist.name)
        XCTAssertEqual(decodedArtist.spotify, originalArtist.spotify)
        XCTAssertEqual(decodedArtist.bio, originalArtist.bio)
    }
    
    // MARK: - SearchArtistsResponse Tests
    
    func testSearchArtistsResponse_Codable() throws {
        let artist = MusicNerdArtist(
            id: "1",
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
        
        let response = SearchArtistsResponse(results: [artist])
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SearchArtistsResponse.self, from: data)
        
        XCTAssertEqual(decoded.results.count, 1)
        XCTAssertEqual(decoded.results[0].name, "Test Artist")
    }
    
    // MARK: - ArtistBioResponse Tests
    
    func testArtistBioResponse_Codable() throws {
        let response = ArtistBioResponse(bio: "Test bio", artist: nil)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ArtistBioResponse.self, from: data)
        
        XCTAssertEqual(decoded.bio, "Test bio")
        XCTAssertNil(decoded.artist)
    }
    
    // MARK: - FunFactsResponse Tests
    
    func testFunFactsResponse_Codable() throws {
        let response = FunFactsResponse(funFact: "Interesting fact!", artist: nil)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FunFactsResponse.self, from: data)
        
        XCTAssertEqual(decoded.funFact, "Interesting fact!")
        XCTAssertNil(decoded.artist)
    }
    
    // MARK: - MusicNerdAPIError Tests
    
    func testMusicNerdAPIError_Codable() throws {
        let error = MusicNerdAPIError(error: "Not found", message: "Artist not found")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(error)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MusicNerdAPIError.self, from: data)
        
        XCTAssertEqual(decoded.error, "Not found")
        XCTAssertEqual(decoded.message, "Artist not found")
    }
    
    func testMusicNerdAPIError_IsError() {
        let error = MusicNerdAPIError(error: "Test error", message: nil)
        XCTAssertTrue(error is Error)
    }
}