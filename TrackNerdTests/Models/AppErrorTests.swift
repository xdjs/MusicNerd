import XCTest
@testable import MusicNerd

final class AppErrorTests: XCTestCase {
    
    func testShazamErrorDescriptions() {
        let noMatchError = AppError.shazamError(.noMatch)
        XCTAssertEqual(noMatchError.errorDescription, "No song match found")
        XCTAssertEqual(noMatchError.recoverySuggestion, "Try playing the song louder or getting closer to the source.")
        
        let permissionError = AppError.shazamError(.noMicrophonePermission)
        XCTAssertEqual(permissionError.errorDescription, "Microphone access required")
        XCTAssertEqual(permissionError.recoverySuggestion, "Please enable microphone access in Settings to identify music.")
        
        let recognitionError = AppError.shazamError(.recognitionFailed("Test message"))
        XCTAssertEqual(recognitionError.errorDescription, "Recognition failed: Test message")
    }
    
    func testNetworkErrorDescriptions() {
        let noConnectionError = AppError.networkError(.noConnection)
        XCTAssertEqual(noConnectionError.errorDescription, "No internet connection")
        
        let timeoutError = AppError.networkError(.timeout)
        XCTAssertEqual(timeoutError.errorDescription, "Request timed out")
        
        let serverError = AppError.networkError(.serverError(500))
        XCTAssertEqual(serverError.errorDescription, "Server error (500)")
        
        let rateLimitError = AppError.networkError(.rateLimited)
        XCTAssertEqual(rateLimitError.errorDescription, "Too many requests")
    }
    
    func testStorageErrorDescriptions() {
        let saveError = AppError.storageError(.saveFailed)
        XCTAssertEqual(saveError.errorDescription, "Failed to save data")
        
        let loadError = AppError.storageError(.loadFailed)
        XCTAssertEqual(loadError.errorDescription, "Failed to load data")
        
        let diskFullError = AppError.storageError(.diskFull)
        XCTAssertEqual(diskFullError.errorDescription, "Not enough storage space")
        XCTAssertEqual(diskFullError.recoverySuggestion, "Free up some storage space and try again.")
    }
    
    func testEnrichmentErrorDescriptions() {
        let noDataError = AppError.enrichmentError(.noData)
        XCTAssertEqual(noDataError.errorDescription, "No enrichment data available")
        
        let quotaError = AppError.enrichmentError(.quotaExceeded)
        XCTAssertEqual(quotaError.errorDescription, "Enrichment quota exceeded")
        XCTAssertEqual(quotaError.recoverySuggestion, "Please try again tomorrow or upgrade your plan.")
        
        let networkError = AppError.enrichmentError(.networkError)
        XCTAssertEqual(networkError.errorDescription, "Network error occurred")
        
        let timeoutError = AppError.enrichmentError(.timeout)
        XCTAssertEqual(timeoutError.errorDescription, "Request timed out")
        
        let artistNotFoundError = AppError.enrichmentError(.artistNotFound)
        XCTAssertEqual(artistNotFoundError.errorDescription, "Artist not found in database")
        
        let serverError = AppError.enrichmentError(.serverError)
        XCTAssertEqual(serverError.errorDescription, "Server error occurred")
        
        let rateLimitedError = AppError.enrichmentError(.rateLimited)
        XCTAssertEqual(rateLimitedError.errorDescription, "Rate limit exceeded")
    }
    
    func testPermissionErrorDescriptions() {
        let deniedError = AppError.permissionError(.microphoneDenied)
        XCTAssertEqual(deniedError.errorDescription, "Microphone access denied")
        XCTAssertEqual(deniedError.recoverySuggestion, "Please enable microphone access in Settings > Privacy & Security > Microphone > Music Nerd ID.")
        
        let restrictedError = AppError.permissionError(.microphoneRestricted)
        XCTAssertEqual(restrictedError.errorDescription, "Microphone access restricted")
        
        let notDeterminedError = AppError.permissionError(.microphoneNotDetermined)
        XCTAssertEqual(notDeterminedError.errorDescription, "Microphone permission required")
    }
    
    func testUnknownError() {
        let unknownError = AppError.unknown("Something went wrong")
        XCTAssertEqual(unknownError.errorDescription, "Something went wrong")
        XCTAssertEqual(unknownError.recoverySuggestion, "Please try again or contact support if the problem persists.")
    }
    
    func testErrorEquality() {
        let error1 = AppError.shazamError(.noMatch)
        let error2 = AppError.shazamError(.noMatch)
        let error3 = AppError.networkError(.noConnection)
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    func testResultTypeAlias() {
        let successResult: Result<String> = .success("test")
        let failureResult: Result<String> = .failure(.networkError(.noConnection))
        
        switch successResult {
        case .success(let value):
            XCTAssertEqual(value, "test")
        case .failure:
            XCTFail("Expected success")
        }
        
        switch failureResult {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - EnrichmentError Fallback Content Tests
    
    func testEnrichmentErrorFallbackMessages() {
        XCTAssertEqual(EnrichmentError.networkError.fallbackMessage, "Unable to load content - check your internet connection and try again")
        XCTAssertEqual(EnrichmentError.timeout.fallbackMessage, "Content is taking too long to load - try again later")
        XCTAssertEqual(EnrichmentError.artistNotFound.fallbackMessage, "This artist isn't available in our music database yet")
        XCTAssertEqual(EnrichmentError.serverError.fallbackMessage, "Our music service is experiencing issues - try again later")
        XCTAssertEqual(EnrichmentError.rateLimited.fallbackMessage, "Too many requests - try again in a moment")
        XCTAssertEqual(EnrichmentError.noData.fallbackMessage, "Content is not available for this artist")
        XCTAssertEqual(EnrichmentError.quotaExceeded.fallbackMessage, "Daily content limit reached - try again tomorrow")
    }
    
    func testEnrichmentErrorRetryability() {
        // Retryable errors
        XCTAssertTrue(EnrichmentError.networkError.isRetryable)
        XCTAssertTrue(EnrichmentError.timeout.isRetryable)
        XCTAssertTrue(EnrichmentError.serverError.isRetryable)
        XCTAssertTrue(EnrichmentError.rateLimited.isRetryable)
        
        // Non-retryable errors
        XCTAssertFalse(EnrichmentError.artistNotFound.isRetryable)
        XCTAssertFalse(EnrichmentError.noData.isRetryable)
        XCTAssertFalse(EnrichmentError.invalidData.isRetryable)
        XCTAssertFalse(EnrichmentError.processingFailed.isRetryable)
        XCTAssertFalse(EnrichmentError.quotaExceeded.isRetryable)
    }
    
    func testAppErrorToEnrichmentErrorConversion() {
        // Network errors
        XCTAssertEqual(EnrichmentError.from(.networkError(.noConnection)), .networkError)
        XCTAssertEqual(EnrichmentError.from(.networkError(.invalidResponse)), .networkError)
        XCTAssertEqual(EnrichmentError.from(.networkError(.timeout)), .timeout)
        XCTAssertEqual(EnrichmentError.from(.networkError(.serverError(500))), .serverError)
        XCTAssertEqual(EnrichmentError.from(.networkError(.rateLimited)), .rateLimited)
        
        // MusicNerd errors
        XCTAssertEqual(EnrichmentError.from(.musicNerdError(.artistNotFound)), .artistNotFound)
        XCTAssertEqual(EnrichmentError.from(.musicNerdError(.noBioAvailable)), .noData)
        XCTAssertEqual(EnrichmentError.from(.musicNerdError(.noFunFactAvailable)), .noData)
        XCTAssertEqual(EnrichmentError.from(.musicNerdError(.apiError("test"))), .serverError)
        
        // Other errors
        XCTAssertEqual(EnrichmentError.from(.storageError(.saveFailed)), .processingFailed)
        XCTAssertEqual(EnrichmentError.from(.unknown("test")), .processingFailed)
    }
    
    func testEnrichmentErrorCodableConformance() throws {
        let originalErrors: [EnrichmentError] = [
            .networkError,
            .timeout,
            .artistNotFound,
            .serverError,
            .rateLimited,
            .noData,
            .quotaExceeded
        ]
        
        for originalError in originalErrors {
            let encoded = try JSONEncoder().encode(originalError)
            let decoded = try JSONDecoder().decode(EnrichmentError.self, from: encoded)
            XCTAssertEqual(decoded, originalError, "Failed to encode/decode \(originalError)")
        }
    }
    
    func testEnrichmentErrorEquality() {
        XCTAssertEqual(EnrichmentError.networkError, EnrichmentError.networkError)
        XCTAssertEqual(EnrichmentError.artistNotFound, EnrichmentError.artistNotFound)
        XCTAssertNotEqual(EnrichmentError.networkError, EnrichmentError.timeout)
        XCTAssertNotEqual(EnrichmentError.rateLimited, EnrichmentError.artistNotFound)
    }
}
