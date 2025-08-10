import XCTest
@testable import TrackNerd

// MARK: - Mock Services for Error Testing

class MockMusicNerdServiceWithErrors: MusicNerdServiceProtocol {
    
    enum MockErrorType {
        case none
        case artistNotFound
        case networkError
        case timeout
        case rateLimited
        case serverError
        case bioError
        case funFactError(FunFactType)
        case mixedErrors
    }
    
    var errorType: MockErrorType = .none
    
    func searchArtist(name: String) async -> Result<MusicNerdArtist> {
        switch errorType {
        case .artistNotFound:
            return .failure(.musicNerdError(.artistNotFound))
        case .networkError:
            return .failure(.networkError(.noConnection))
        case .timeout:
            return .failure(.networkError(.timeout))
        case .rateLimited:
            return .failure(.networkError(.rateLimited))
        case .serverError:
            return .failure(.networkError(.serverError(500)))
        default:
            // Return successful artist for other error types
            return .success(MusicNerdArtist(
                artistId: "test-123",
                name: name,
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
            ))
        }
    }
    
    func getArtistBio(artistId: String) async -> Result<String> {
        switch errorType {
        case .bioError, .mixedErrors:
            return .failure(.networkError(.timeout))
        case .rateLimited:
            return .failure(.networkError(.rateLimited))
        default:
            return .success("Mock bio for \(artistId)")
        }
    }
    
    func getFunFact(artistId: String, type: FunFactType) async -> Result<String> {
        switch errorType {
        case .funFactError(let errorType) where errorType == type:
            return .failure(.musicNerdError(.noFunFactAvailable))
        case .mixedErrors:
            // Mix different error types for different fun fact types
            switch type {
            case .lore:
                return .failure(.networkError(.rateLimited))
            case .bts:
                return .success("Mock BTS fact")
            case .activity:
                return .failure(.musicNerdError(.noFunFactAvailable))
            case .surprise:
                return .failure(.networkError(.timeout))
            }
        case .rateLimited:
            return .failure(.networkError(.rateLimited))
        default:
            return .success("Mock \(type.rawValue) fact for \(artistId)")
        }
    }
}

final class EnrichmentErrorHandlingTests: XCTestCase {
    
    var openAIService: OpenAIService!
    var mockMusicNerdService: MockMusicNerdServiceWithErrors!
    
    override func setUp() {
        super.setUp()
        mockMusicNerdService = MockMusicNerdServiceWithErrors()
        openAIService = OpenAIService(musicNerdService: mockMusicNerdService)
    }
    
    override func tearDown() {
        openAIService = nil
        mockMusicNerdService = nil
        super.tearDown()
    }
    
    // MARK: - Artist Search Error Tests
    
    func testEnrichSong_ArtistNotFound_ShouldReturnEnrichmentDataWithErrors() async {
        mockMusicNerdService.errorType = .artistNotFound
        
        let songMatch = SongMatch(title: "Test Song", artist: "Unknown Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            // Should have error information
            XCTAssertEqual(enrichmentData.bioError, .artistNotFound)
            XCTAssertEqual(enrichmentData.funFactErrors["lore"], .artistNotFound)
            XCTAssertEqual(enrichmentData.funFactErrors["bts"], .artistNotFound)
            XCTAssertEqual(enrichmentData.funFactErrors["activity"], .artistNotFound)
            XCTAssertEqual(enrichmentData.funFactErrors["surprise"], .artistNotFound)
            
            // Should not have content
            XCTAssertNil(enrichmentData.artistBio)
            XCTAssertTrue(enrichmentData.funFacts.isEmpty)
            
        case .failure(let error):
            XCTFail("Expected success with errors but got failure: \(error)")
        }
    }
    
    func testEnrichSong_NetworkError_ShouldReturnEnrichmentDataWithNetworkErrors() async {
        mockMusicNerdService.errorType = .networkError
        
        let songMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            XCTAssertEqual(enrichmentData.bioError, .networkError)
            XCTAssertEqual(enrichmentData.funFactErrors["lore"], .networkError)
            XCTAssertEqual(enrichmentData.funFactErrors["bts"], .networkError)
            XCTAssertEqual(enrichmentData.funFactErrors["activity"], .networkError)
            XCTAssertEqual(enrichmentData.funFactErrors["surprise"], .networkError)
            
        case .failure(let error):
            XCTFail("Expected success with errors but got failure: \(error)")
        }
    }
    
    func testEnrichSong_RateLimited_ShouldReturnEnrichmentDataWithRateLimitErrors() async {
        mockMusicNerdService.errorType = .rateLimited
        
        let songMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            XCTAssertEqual(enrichmentData.bioError, .rateLimited)
            XCTAssertEqual(enrichmentData.funFactErrors["lore"], .rateLimited)
            XCTAssertEqual(enrichmentData.funFactErrors["bts"], .rateLimited)
            XCTAssertEqual(enrichmentData.funFactErrors["activity"], .rateLimited)
            XCTAssertEqual(enrichmentData.funFactErrors["surprise"], .rateLimited)
            
        case .failure(let error):
            XCTFail("Expected success with errors but got failure: \(error)")
        }
    }
    
    // MARK: - Individual Content Error Tests
    
    func testEnrichSong_BioError_ShouldTrackBioErrorSpecifically() async {
        mockMusicNerdService.errorType = .bioError
        
        let songMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            // Bio should have error
            XCTAssertEqual(enrichmentData.bioError, .timeout)
            XCTAssertNil(enrichmentData.artistBio)
            
            // Fun facts should be successful
            XCTAssertNil(enrichmentData.funFactErrors["lore"])
            XCTAssertNil(enrichmentData.funFactErrors["bts"])
            XCTAssertNil(enrichmentData.funFactErrors["activity"])
            XCTAssertNil(enrichmentData.funFactErrors["surprise"])
            
            XCTAssertEqual(enrichmentData.funFacts["lore"], "Mock lore fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["bts"], "Mock bts fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["activity"], "Mock activity fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["surprise"], "Mock surprise fact for test-123")
            
        case .failure(let error):
            XCTFail("Expected success with bio error but got failure: \(error)")
        }
    }
    
    func testEnrichSong_SpecificFunFactError_ShouldTrackIndividualFunFactError() async {
        mockMusicNerdService.errorType = .funFactError(.lore)
        
        let songMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            // Bio should be successful
            XCTAssertNil(enrichmentData.bioError)
            XCTAssertEqual(enrichmentData.artistBio, "Mock bio for test-123")
            
            // Only lore should have error
            XCTAssertEqual(enrichmentData.funFactErrors["lore"], .noData)
            XCTAssertNil(enrichmentData.funFactErrors["bts"])
            XCTAssertNil(enrichmentData.funFactErrors["activity"])
            XCTAssertNil(enrichmentData.funFactErrors["surprise"])
            
            // Other fun facts should be successful
            XCTAssertNil(enrichmentData.funFacts["lore"])
            XCTAssertEqual(enrichmentData.funFacts["bts"], "Mock bts fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["activity"], "Mock activity fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["surprise"], "Mock surprise fact for test-123")
            
        case .failure(let error):
            XCTFail("Expected success with lore error but got failure: \(error)")
        }
    }
    
    // MARK: - Mixed Error Scenarios
    
    func testEnrichSong_MixedErrors_ShouldTrackEachErrorIndividually() async {
        mockMusicNerdService.errorType = .mixedErrors
        
        let songMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            // Bio should have timeout error
            XCTAssertEqual(enrichmentData.bioError, .timeout)
            XCTAssertNil(enrichmentData.artistBio)
            
            // Mixed fun fact results
            XCTAssertEqual(enrichmentData.funFactErrors["lore"], .rateLimited)
            XCTAssertNil(enrichmentData.funFactErrors["bts"]) // Should be successful
            XCTAssertEqual(enrichmentData.funFactErrors["activity"], .noData)
            XCTAssertEqual(enrichmentData.funFactErrors["surprise"], .timeout)
            
            // Check successful content
            XCTAssertNil(enrichmentData.funFacts["lore"])
            XCTAssertEqual(enrichmentData.funFacts["bts"], "Mock BTS fact")
            XCTAssertNil(enrichmentData.funFacts["activity"])
            XCTAssertNil(enrichmentData.funFacts["surprise"])
            
        case .failure(let error):
            XCTFail("Expected success with mixed errors but got failure: \(error)")
        }
    }
    
    // MARK: - Successful Enrichment Tests
    
    func testEnrichSong_AllSuccessful_ShouldHaveNoErrors() async {
        mockMusicNerdService.errorType = .none
        
        let songMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let result = await openAIService.enrichSong(songMatch)
        
        switch result {
        case .success(let enrichmentData):
            // Should have no errors
            XCTAssertNil(enrichmentData.bioError)
            XCTAssertTrue(enrichmentData.funFactErrors.isEmpty)
            
            // Should have all content
            XCTAssertEqual(enrichmentData.artistBio, "Mock bio for test-123")
            XCTAssertEqual(enrichmentData.funFacts["lore"], "Mock lore fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["bts"], "Mock bts fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["activity"], "Mock activity fact for test-123")
            XCTAssertEqual(enrichmentData.funFacts["surprise"], "Mock surprise fact for test-123")
            
        case .failure(let error):
            XCTFail("Expected successful enrichment but got failure: \(error)")
        }
    }
    
    // MARK: - Error Conversion Tests
    
    func testEnrichmentErrorConversion() {
        // Test various AppError to EnrichmentError conversions
        let testCases: [(AppError, EnrichmentError)] = [
            (.networkError(.noConnection), .networkError),
            (.networkError(.timeout), .timeout),
            (.networkError(.rateLimited), .rateLimited),
            (.networkError(.serverError(500)), .serverError),
            (.musicNerdError(.artistNotFound), .artistNotFound),
            (.musicNerdError(.noBioAvailable), .noData),
            (.musicNerdError(.noFunFactAvailable), .noData),
            (.storageError(.saveFailed), .processingFailed)
        ]
        
        for (appError, expectedEnrichmentError) in testCases {
            let result = EnrichmentError.from(appError)
            XCTAssertEqual(result, expectedEnrichmentError, 
                          "Failed to convert \(appError) to \(expectedEnrichmentError), got \(result)")
        }
    }
}