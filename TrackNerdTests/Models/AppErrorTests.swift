import XCTest
@testable import TrackNerd

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
    }
    
    func testPermissionErrorDescriptions() {
        let deniedError = AppError.permissionError(.microphoneDenied)
        XCTAssertEqual(deniedError.errorDescription, "Microphone access denied")
        XCTAssertEqual(deniedError.recoverySuggestion, "Please enable microphone access in Settings > Privacy & Security > Microphone > TrackNerd.")
        
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
}
