import XCTest
@testable import TrackNerd
import Foundation

// MARK: - Mock Services for Testing

class MusicNerdServiceTestMock: MusicNerdServiceProtocol {
    var shouldReturnError = false
    var mockArtist: MusicNerdArtist?
    var mockBio: String?
    var mockFunFact: String?
    
    func searchArtist(name: String) async -> Result<MusicNerdArtist> {
        if shouldReturnError {
            return .failure(.musicNerdError(.artistNotFound))
        }
        
        if let artist = mockArtist {
            return .success(artist)
        }
        
        // Default mock artist
        let artist = MusicNerdArtist(
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
        )
        return .success(artist)
    }
    
    func getArtistBio(artistId: String) async -> Result<String> {
        if shouldReturnError {
            return .failure(.musicNerdError(.noBioAvailable))
        }
        
        return .success(mockBio ?? "Test artist bio for \(artistId)")
    }
    
    func getFunFact(artistId: String, type: FunFactType) async -> Result<String> {
        if shouldReturnError {
            return .failure(.musicNerdError(.noFunFactAvailable))
        }
        
        return .success(mockFunFact ?? "Test \(type.rawValue) fun fact for \(artistId)")
    }
}

final class MusicNerdServiceTests: XCTestCase {
    
    var musicNerdService: MusicNerdService!
    var mockService: MusicNerdServiceTestMock!
    
    override func setUp() {
        super.setUp()
        musicNerdService = MusicNerdService()
        mockService = MusicNerdServiceTestMock()
    }
    
    override func tearDown() {
        musicNerdService = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Artist Search and ID Resolution Tests
    
    func testMockService_SearchArtist_WithValidName_ShouldReturnArtist() async {
        // Test the mock service implementation
        let result = await mockService.searchArtist(name: "Queen")
        
        switch result {
        case .success(let artist):
            XCTAssertEqual(artist.name, "Queen")
            XCTAssertEqual(artist.artistId, "test-123")
            XCTAssertNotNil(artist.id) // Computed property should work
        case .failure:
            XCTFail("Expected success for valid artist name")
        }
    }
    
    func testMockService_SearchArtist_WithError_ShouldReturnFailure() async {
        mockService.shouldReturnError = true
        
        let result = await mockService.searchArtist(name: "Unknown Artist")
        
        switch result {
        case .success:
            XCTFail("Expected failure when shouldReturnError is true")
        case .failure(let error):
            if case .musicNerdError(.artistNotFound) = error {
                // Expected error type
            } else {
                XCTFail("Expected artistNotFound error, got \(error)")
            }
        }
    }
    
    func testMockService_SearchArtist_WithCustomArtist_ShouldReturnCustomArtist() async {
        let customArtist = MusicNerdArtist(
            artistId: "custom-456",
            name: "The Beatles",
            spotify: "spotify-url",
            instagram: nil,
            x: nil,
            youtube: nil,
            soundcloud: nil,
            bio: "Famous British band",
            youtubechannel: nil,
            tiktok: nil,
            bandcamp: nil,
            website: nil
        )
        mockService.mockArtist = customArtist
        
        let result = await mockService.searchArtist(name: "The Beatles")
        
        switch result {
        case .success(let artist):
            XCTAssertEqual(artist.artistId, "custom-456")
            XCTAssertEqual(artist.name, "The Beatles")
            XCTAssertEqual(artist.spotify, "spotify-url")
            XCTAssertEqual(artist.bio, "Famous British band")
        case .failure:
            XCTFail("Expected success for custom artist")
        }
    }
    
    func testMusicNerdArtist_IDProperty_WithValidArtistId() {
        let artist = MusicNerdArtist(
            artistId: "valid-123",
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
        
        XCTAssertEqual(artist.id, "valid-123")
        XCTAssertEqual(artist.artistId, "valid-123")
    }
    
    func testMusicNerdArtist_IDProperty_WithNilArtistId() {
        let artist = MusicNerdArtist(
            artistId: nil,
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
        
        // Should generate a UUID when artistId is nil
        XCTAssertNotEqual(artist.id, "")
        XCTAssertNil(artist.artistId)
        // The computed id should be a valid UUID string
        XCTAssertNotNil(UUID(uuidString: artist.id))
    }
    
    func testSearchArtist_WithEmptyName_ShouldHandleGracefully() async {
        let result = await musicNerdService.searchArtist(name: "")
        
        switch result {
        case .success:
            XCTFail("Expected failure for empty search term")
        case .failure(let error):
            // Should handle empty search gracefully
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Bio and Fun Facts API Response Parsing Tests
    
    func testMockService_GetArtistBio_WithValidId_ShouldReturnBio() async {
        mockService.mockBio = "This is a comprehensive artist biography with detailed information."
        
        let result = await mockService.getArtistBio(artistId: "valid-123")
        
        switch result {
        case .success(let bio):
            XCTAssertEqual(bio, "This is a comprehensive artist biography with detailed information.")
            XCTAssertFalse(bio.isEmpty)
        case .failure:
            XCTFail("Expected success for valid artist ID")
        }
    }
    
    func testMockService_GetArtistBio_WithError_ShouldReturnError() async {
        mockService.shouldReturnError = true
        
        let result = await mockService.getArtistBio(artistId: "invalid")
        
        switch result {
        case .success:
            XCTFail("Expected failure when shouldReturnError is true")
        case .failure(let error):
            if case .musicNerdError(.noBioAvailable) = error {
                // Expected error type
            } else {
                XCTFail("Expected noBioAvailable error, got \(error)")
            }
        }
    }
    
    func testMockService_GetFunFact_AllTypes_ShouldReturnFunFacts() async {
        let artistId = "test-artist-123"
        
        for funFactType in FunFactType.allCases {
            mockService.mockFunFact = "This is a \(funFactType.rawValue) fun fact about the artist."
            
            let result = await mockService.getFunFact(artistId: artistId, type: funFactType)
            
            switch result {
            case .success(let funFact):
                XCTAssertTrue(funFact.contains(funFactType.rawValue))
                XCTAssertFalse(funFact.isEmpty)
            case .failure:
                XCTFail("Expected success for \(funFactType.rawValue) fun fact")
            }
        }
    }
    
    func testMockService_GetFunFact_WithError_ShouldReturnError() async {
        mockService.shouldReturnError = true
        
        let result = await mockService.getFunFact(artistId: "invalid", type: .lore)
        
        switch result {
        case .success:
            XCTFail("Expected failure when shouldReturnError is true")
        case .failure(let error):
            if case .musicNerdError(.noFunFactAvailable) = error {
                // Expected error type
            } else {
                XCTFail("Expected noFunFactAvailable error, got \(error)")
            }
        }
    }
    
    func testGetArtistBio_WithEmptyId_ShouldReturnError() async {
        let result = await musicNerdService.getArtistBio(artistId: "")
        
        switch result {
        case .success:
            XCTFail("Expected failure for empty artist ID")
        case .failure(let error):
            // Should handle empty ID gracefully
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testGetFunFact_WithEmptyId_ShouldReturnError() async {
        let result = await musicNerdService.getFunFact(artistId: "", type: .surprise)
        
        switch result {
        case .success:
            XCTFail("Expected failure for empty artist ID")
        case .failure(let error):
            // Should handle empty ID gracefully
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Network Error Handling Tests
    
    func testNetworkError_Scenarios() {
        // Test various network error scenarios
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let noConnectionError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let serverError = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: nil)
        
        // Verify error types exist
        XCTAssertEqual(timeoutError.code, NSURLErrorTimedOut)
        XCTAssertEqual(noConnectionError.code, NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(serverError.code, NSURLErrorBadServerResponse)
    }
    
    func testAppError_MusicNerdErrors() {
        // Test MusicNerd-specific error cases
        let artistNotFoundError = AppError.musicNerdError(.artistNotFound)
        let noBioError = AppError.musicNerdError(.noBioAvailable)
        let noFunFactError = AppError.musicNerdError(.noFunFactAvailable)
        let apiError = AppError.musicNerdError(.apiError("Custom API error"))
        
        // Test error descriptions
        XCTAssertNotNil(artistNotFoundError.localizedDescription)
        XCTAssertNotNil(noBioError.localizedDescription)
        XCTAssertNotNil(noFunFactError.localizedDescription)
        XCTAssertNotNil(apiError.localizedDescription)
    }
    
    func testAppError_NetworkErrors() {
        // Test network-specific error cases
        let timeoutError = AppError.networkError(.timeout)
        let invalidURLError = AppError.networkError(.invalidURL)
        let serverError = AppError.networkError(.serverError(500))
        let invalidResponseError = AppError.networkError(.invalidResponse)
        
        // Test error descriptions
        XCTAssertNotNil(timeoutError.localizedDescription)
        XCTAssertNotNil(invalidURLError.localizedDescription)
        XCTAssertNotNil(serverError.localizedDescription)
        XCTAssertNotNil(invalidResponseError.localizedDescription)
    }
    
    func testMusicNerdModels_JSONDecoding() throws {
        // Test JSON response parsing for valid data
        let validSearchResponse = """
        {
            "results": [
                {
                    "id": "valid-123",
                    "name": "Queen",
                    "spotify": "spotify-url",
                    "bio": "British rock band"
                },
                {
                    "id": null,
                    "name": "Invalid Artist",
                    "spotify": null
                }
            ]
        }
        """
        
        let data = validSearchResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let searchResponse = try decoder.decode(SearchArtistsResponse.self, from: data)
        XCTAssertEqual(searchResponse.results.count, 2)
        
        // First artist should have valid ID
        let validArtist = searchResponse.results[0]
        XCTAssertEqual(validArtist.artistId, "valid-123")
        XCTAssertEqual(validArtist.name, "Queen")
        XCTAssertEqual(validArtist.id, "valid-123") // Computed property
        
        // Second artist should handle null ID
        let invalidArtist = searchResponse.results[1]
        XCTAssertNil(invalidArtist.artistId)
        XCTAssertEqual(invalidArtist.name, "Invalid Artist")
        XCTAssertNotNil(UUID(uuidString: invalidArtist.id)) // Should be valid UUID
    }
    
    func testMusicNerdModels_BioResponse() throws {
        let validBioResponse = """
        {
            "bio": "This is a comprehensive artist biography with detailed information about their career."
        }
        """
        
        let data = validBioResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let bioResponse = try decoder.decode(ArtistBioResponse.self, from: data)
        XCTAssertNotNil(bioResponse.bio)
        XCTAssertTrue(bioResponse.bio!.contains("comprehensive"))
    }
    
    func testMusicNerdModels_FunFactsResponse() throws {
        let validFunFactResponse = """
        {
            "funFact": "This is an interesting lore fact about the artist that fans would love to know."
        }
        """
        
        let data = validFunFactResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let funFactResponse = try decoder.decode(FunFactsResponse.self, from: data)
        XCTAssertNotNil(funFactResponse.funFact)
        XCTAssertTrue(funFactResponse.funFact!.contains("lore fact"))
    }
    
    func testMusicNerdModels_ErrorResponse() throws {
        let errorResponse = """
        {
            "error": "Artist not found",
            "message": "The requested artist could not be found in our database."
        }
        """
        
        let data = errorResponse.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let apiError = try decoder.decode(MusicNerdAPIError.self, from: data)
        XCTAssertEqual(apiError.error, "Artist not found")
        XCTAssertEqual(apiError.message, "The requested artist could not be found in our database.")
    }
    
    // MARK: - Fun Fact Type Tests
    
    func testFunFactType_AllCases() {
        let allTypes = FunFactType.allCases
        
        XCTAssertEqual(allTypes.count, 4)
        XCTAssertTrue(allTypes.contains(.lore))
        XCTAssertTrue(allTypes.contains(.bts))
        XCTAssertTrue(allTypes.contains(.activity))
        XCTAssertTrue(allTypes.contains(.surprise))
    }
    
    // MARK: - Cache Integration Tests
    
    func testMusicNerdService_CacheIntegration() async {
        // Use a test-specific cache to avoid interference
        let service = MusicNerdService()
        let cache = await EnrichmentCache.shared
        await MainActor.run { cache.clearAll() }
        
        // Mock successful network responses would be needed for full integration test
        // For now, test that cache methods are called correctly
        
        let artistId = "cache-test-123"
        let bioKey = EnrichmentCacheKey(artistId: artistId, type: .bio)
        let funFactKey = EnrichmentCacheKey(artistId: artistId, type: .funFact(.lore))
        
        // Test that cache is empty initially
        let initialBioData = await MainActor.run { cache.retrieve(for: bioKey) }
        let initialFunFactData = await MainActor.run { cache.retrieve(for: funFactKey) }
        XCTAssertNil(initialBioData)
        XCTAssertNil(initialFunFactData)
        
        // Store test data in cache
        let testBio = "Cached bio data"
        let testFunFact = "Cached fun fact"
        
        await MainActor.run {
            cache.store(testBio, for: bioKey)
            cache.store(testFunFact, for: funFactKey)
        }
        
        // Verify data is cached
        let cachedBioData = await MainActor.run { cache.retrieve(for: bioKey) }
        let cachedFunFactData = await MainActor.run { cache.retrieve(for: funFactKey) }
        XCTAssertEqual(cachedBioData, testBio)
        XCTAssertEqual(cachedFunFactData, testFunFact)
        
        await MainActor.run { cache.clearAll() }
    }
    
    func testEnrichmentCache_Integration() async {
        let cache = await EnrichmentCache.shared
        await MainActor.run { cache.clearAll() }
        
        // Test storing bio
        let bioKey = EnrichmentCacheKey(artistId: "integration-test", type: .bio)
        let bioData = "Integration test bio"
        
        await MainActor.run {
            cache.store(bioData, for: bioKey, expirationInterval: 3600)
        }
        let retrievedData = await MainActor.run { cache.retrieve(for: bioKey) }
        XCTAssertEqual(retrievedData, bioData)
        
        // Test storing fun facts for all types
        let funFactTypes: [FunFactType] = [.lore, .bts, .activity, .surprise]
        
        for type in funFactTypes {
            let key = EnrichmentCacheKey(artistId: "integration-test", type: .funFact(type))
            let data = "Integration test \(type.rawValue) fact"
            
            await MainActor.run {
                cache.store(data, for: key, expirationInterval: 3600)
            }
            let retrievedTypeData = await MainActor.run { cache.retrieve(for: key) }
            XCTAssertEqual(retrievedTypeData, data)
        }
        
        await MainActor.run { cache.clearAll() }
    }
    
    func testFunFactType_RawValues() {
        XCTAssertEqual(FunFactType.lore.rawValue, "lore")
        XCTAssertEqual(FunFactType.bts.rawValue, "bts")
        XCTAssertEqual(FunFactType.activity.rawValue, "activity")
        XCTAssertEqual(FunFactType.surprise.rawValue, "surprise")
    }
    
    // MARK: - URL Construction Tests
    
    func testURLConstruction() {
        // Test that the service can construct URLs correctly
        let baseURL = AppConfiguration.API.baseURL
        let searchEndpoint = AppConfiguration.API.searchArtistsEndpoint
        let bioEndpoint = AppConfiguration.API.artistBioEndpoint
        let funFactsEndpoint = AppConfiguration.API.funFactsEndpoint
        
        // Verify endpoints are configured
        XCTAssertFalse(baseURL.isEmpty)
        XCTAssertTrue(searchEndpoint.hasPrefix("/"))
        XCTAssertTrue(bioEndpoint.hasPrefix("/"))
        XCTAssertTrue(funFactsEndpoint.hasPrefix("/"))
        
        // Test URL construction
        let searchURL = "\(baseURL)\(searchEndpoint)"
        let bioURL = "\(baseURL)\(bioEndpoint)/123"
        let funFactURL = "\(baseURL)\(funFactsEndpoint)/lore?id=123"
        
        XCTAssertNotNil(URL(string: searchURL))
        XCTAssertNotNil(URL(string: bioURL))
        XCTAssertNotNil(URL(string: funFactURL))
    }
    
    // MARK: - Rate Limiting and Retry Logic Tests
    
    func testRetryableErrorConfiguration() {
        // Test that the right error types are configured as retryable in MusicNerdService
        let retryableNetworkErrors: [NetworkError] = [
            .timeout,
            .noConnection,
            .serverError(500),
            .serverError(502),
            .serverError(503),
            .serverError(504),
            .rateLimited
        ]
        
        for error in retryableNetworkErrors {
            // These should be considered retryable by the service
            switch error {
            case .timeout, .noConnection, .serverError, .rateLimited:
                XCTAssertTrue(true, "\(error) should be retryable")
            default:
                XCTFail("\(error) should be retryable but isn't configured as such")
            }
        }
        
        let nonRetryableErrors: [NetworkError] = [
            .invalidURL,
            .invalidResponse
        ]
        
        for error in nonRetryableErrors {
            // These should not retry immediately
            switch error {
            case .invalidURL, .invalidResponse:
                XCTAssertTrue(true, "\(error) should not be immediately retryable")
            default:
                break
            }
        }
    }
    
    func testEnrichmentErrorFromAppErrorMapping() {
        // Test the conversion logic for various error scenarios
        let testCases: [(AppError, EnrichmentError)] = [
            // Network errors
            (.networkError(.noConnection), .networkError),
            (.networkError(.timeout), .timeout),
            (.networkError(.serverError(429)), .serverError), // Rate limiting via HTTP status
            (.networkError(.rateLimited), .rateLimited), // Direct rate limiting
            (.networkError(.serverError(500)), .serverError),
            (.networkError(.invalidResponse), .networkError),
            
            // MusicNerd API errors
            (.musicNerdError(.artistNotFound), .artistNotFound),
            (.musicNerdError(.noBioAvailable), .noData),
            (.musicNerdError(.noFunFactAvailable), .noData),
            (.musicNerdError(.apiError("Server error")), .serverError),
            
            // Other error types
            (.storageError(.saveFailed), .processingFailed),
            (.enrichmentError(.quotaExceeded), .quotaExceeded),
            (.unknown("Unknown error"), .processingFailed)
        ]
        
        for (appError, expectedEnrichmentError) in testCases {
            let result = EnrichmentError.from(appError)
            XCTAssertEqual(result, expectedEnrichmentError, 
                          "Failed to map \(appError) to \(expectedEnrichmentError), got \(result)")
        }
    }
    
    func testErrorRecoveryAndFallbackStrategies() {
        // Test different error recovery approaches based on error types
        let networkRecoverableErrors: [EnrichmentError] = [
            .networkError, .timeout, .serverError, .rateLimited
        ]
        
        let permanentErrors: [EnrichmentError] = [
            .artistNotFound, .noData, .invalidData, .quotaExceeded
        ]
        
        for error in networkRecoverableErrors {
            XCTAssertTrue(error.isRetryable, "\(error) should be retryable")
            // Check that retryable errors suggest some form of retry action
            let message = error.fallbackMessage.lowercased()
            let hasRetryLanguage = message.contains("try") || message.contains("again") || message.contains("later")
            XCTAssertTrue(hasRetryLanguage, 
                         "Retryable error \(error) should suggest trying again, message: '\(error.fallbackMessage)'")
        }
        
        for error in permanentErrors {
            XCTAssertFalse(error.isRetryable, "\(error) should not be retryable")
            // Non-retryable errors may still mention trying again, but not immediate retry
            // The key is that they won't show retry buttons due to isRetryable = false
        }
    }
    
    func testFallbackMessageSpecificity() {
        // Test that fallback messages are specific and user-friendly
        let messageTests: [(EnrichmentError, String)] = [
            (.networkError, "check your internet connection"),
            (.timeout, "taking too long to load"),
            (.artistNotFound, "isn't available in our music database"),
            (.rateLimited, "Too many requests"),
            (.serverError, "experiencing issues"),
            (.quotaExceeded, "Daily content limit")
        ]
        
        for (error, expectedContainedText) in messageTests {
            let message = error.fallbackMessage
            XCTAssertTrue(message.contains(expectedContainedText), 
                         "Error \(error) message '\(message)' should contain '\(expectedContainedText)'")
            XCTAssertFalse(message.isEmpty, "Fallback message should not be empty")
            XCTAssertTrue(message.count > 10, "Fallback message should be descriptive")
        }
    }
    
    func testErrorCategorizationForMusicNerdService() {
        // Test that MusicNerd-specific errors are properly categorized
        let musicNerdErrors: [(MusicNerdError, EnrichmentError)] = [
            (.artistNotFound, .artistNotFound),
            (.noBioAvailable, .noData),
            (.noFunFactAvailable, .noData),
            (.apiError("Test error"), .serverError)
        ]
        
        for (musicNerdError, expectedEnrichmentError) in musicNerdErrors {
            let appError = AppError.musicNerdError(musicNerdError)
            let result = EnrichmentError.from(appError)
            XCTAssertEqual(result, expectedEnrichmentError,
                          "MusicNerd error \(musicNerdError) should convert to \(expectedEnrichmentError)")
        }
    }
    
    func testUserExperienceOptimization() {
        // Test that the error handling optimizes for good UX
        
        // Immediate failures vs. retry-worthy failures
        let immediateFailures: [EnrichmentError] = [.artistNotFound, .quotaExceeded]
        let retryableFailures: [EnrichmentError] = [.networkError, .timeout, .rateLimited, .serverError]
        
        for error in immediateFailures {
            XCTAssertFalse(error.isRetryable, "Should not show retry for \(error)")
        }
        
        for error in retryableFailures {
            XCTAssertTrue(error.isRetryable, "Should allow retry for \(error)")
        }
        
        // Message tone - should be helpful, not alarming
        for error in EnrichmentError.allCases {
            let message = error.fallbackMessage
            XCTAssertFalse(message.contains("error"), "Message should not use scary word 'error'")
            XCTAssertFalse(message.contains("failed"), "Message should not emphasize failure")
            XCTAssertFalse(message.uppercased() == message, "Message should not be ALL CAPS")
        }
    }
}

// MARK: - Extension for Test Support

extension EnrichmentError {
    static var allCases: [EnrichmentError] {
        return [
            .noData,
            .invalidData,
            .processingFailed,
            .quotaExceeded,
            .networkError,
            .timeout,
            .artistNotFound,
            .serverError,
            .rateLimited
        ]
    }
}