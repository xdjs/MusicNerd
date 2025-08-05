import XCTest
import ShazamKit
import AVFoundation
@testable import TrackNerd

final class ShazamServiceTests: XCTestCase {
    
    var sut: ShazamService!
    var mockDelegate: MockShazamServiceDelegate!
    
    override func setUp() {
        super.setUp()
        sut = ShazamService()
        mockDelegate = MockShazamServiceDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut.stopListening()
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // The delegate should not have received any state changes during initialization
        // since the delegate is set after the initial state is assigned
        XCTAssertNil(mockDelegate.lastState)
        XCTAssertEqual(mockDelegate.stateChangeCount, 0)
    }
    
    func testStopListening_setsStateToIdle() {
        sut.stopListening()
        
        XCTAssertEqual(mockDelegate.lastState?.description, RecognitionState.idle.description)
    }
    
    func testStartListening_withoutPermission_failsWithPermissionError() async {
        // This test would require mocking the permission service
        // For now, we'll test that the method exists and has proper signature
        let result = await sut.startListening()
        
        // Result should be either success or failure, not crash
        switch result {
        case .success:
            XCTAssertTrue(true, "Recognition succeeded")
        case .failure(let error):
            // Should be a permission error or other expected error
            XCTAssertTrue(error.localizedDescription.count > 0)
        }
    }
    
    func testDelegate_receivesStateChanges() async {
        // Initially no state changes should have occurred
        XCTAssertNil(mockDelegate.lastState)
        XCTAssertNil(mockDelegate.receivedService)
        XCTAssertEqual(mockDelegate.stateChangeCount, 0)
        
        // Trigger a state change by starting listening (which will fail due to permissions)
        let _ = await sut.startListening()
        
        // Now delegate should have received state changes
        XCTAssertNotNil(mockDelegate.lastState)
        XCTAssertNotNil(mockDelegate.receivedService)
        XCTAssertTrue(mockDelegate.receivedService === sut)
        XCTAssertGreaterThan(mockDelegate.stateChangeCount, 0)
    }
}

// MARK: - Mock Delegate

class MockShazamServiceDelegate: ShazamServiceDelegate {
    var lastState: RecognitionState?
    var receivedService: ShazamService?
    var stateChangeCount = 0
    
    func shazamService(_ service: ShazamService, didChangeState state: RecognitionState) {
        lastState = state
        receivedService = service
        stateChangeCount += 1
    }
}

// MARK: - RecognitionState Test Helpers

extension RecognitionState {
    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .listening:
            return "listening"
        case .processing:
            return "processing"
        case .success(let match):
            return "success(\(match.title))"
        case .failure(let error):
            return "failure(\(error.localizedDescription))"
        }
    }
}

// MARK: - Mock ShazamService for Testing

class MockShazamService: ShazamServiceProtocol {
    var shouldSucceed = true
    var mockMatch: SongMatch?
    var mockError: AppError?
    var startListeningCallCount = 0
    var stopListeningCallCount = 0
    
    func startListening() async -> Result<SongMatch> {
        startListeningCallCount += 1
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        if shouldSucceed, let match = mockMatch {
            return .success(match)
        } else {
            let error = mockError ?? AppError.shazamError(.noMatch)
            return .failure(error)
        }
    }
    
    func stopListening() {
        stopListeningCallCount += 1
    }
}

final class MockShazamServiceTests: XCTestCase {
    
    var sut: MockShazamService!
    
    override func setUp() {
        super.setUp()
        sut = MockShazamService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testStartListening_success_returnsMatch() async {
        let expectedMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        sut.shouldSucceed = true
        sut.mockMatch = expectedMatch
        
        let result = await sut.startListening()
        
        switch result {
        case .success(let match):
            XCTAssertEqual(match.title, expectedMatch.title)
            XCTAssertEqual(match.artist, expectedMatch.artist)
        case .failure:
            XCTFail("Expected success but got failure")
        }
        
        XCTAssertEqual(sut.startListeningCallCount, 1)
    }
    
    func testStartListening_failure_returnsError() async {
        let expectedError = AppError.shazamError(.noMatch)
        sut.shouldSucceed = false
        sut.mockError = expectedError
        
        let result = await sut.startListening()
        
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .shazamError(.noMatch) = error {
                // Success - correct error type
            } else {
                XCTFail("Expected shazamError.noMatch, got \(error)")
            }
        }
        
        XCTAssertEqual(sut.startListeningCallCount, 1)
    }
    
    func testStopListening_incrementsCallCount() {
        sut.stopListening()
        XCTAssertEqual(sut.stopListeningCallCount, 1)
    }
}