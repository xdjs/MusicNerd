import XCTest
import AVFoundation
@testable import TrackNerd

final class PermissionServiceTests: XCTestCase {
    
    var sut: PermissionService!
    
    override func setUp() {
        super.setUp()
        sut = PermissionService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testCheckMicrophonePermission_returnsCorrectStatus() {
        let status = sut.checkMicrophonePermission()
        XCTAssertTrue([
            PermissionStatus.notDetermined,
            PermissionStatus.granted,
            PermissionStatus.denied
        ].contains(status))
    }
    
    func testRequestMicrophonePermission_whenAlreadyGranted_returnsGranted() async throws {
        // DISABLED: This test would trigger real system microphone permission dialog
        throw XCTSkip("Skipping test that would trigger system microphone permission dialog")
    }
    
    func testRequestMicrophonePermission_whenDenied_throwsError() async throws {
        // DISABLED: This test would trigger real system microphone permission dialog
        throw XCTSkip("Skipping test that would trigger system microphone permission dialog")
    }
}

// MARK: - Mock Permission Service for Testing

class MockPermissionService: PermissionServiceProtocol {
    var mockStatus: PermissionStatus = .notDetermined
    var shouldThrowError = false
    var errorToThrow: AppError = .permissionError(.microphoneDenied)
    
    func checkMicrophonePermission() -> PermissionStatus {
        return mockStatus
    }
    
    func requestMicrophonePermission() async throws -> PermissionStatus {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockStatus
    }
}

final class MockPermissionServiceTests: XCTestCase {
    
    var sut: MockPermissionService!
    
    override func setUp() {
        super.setUp()
        sut = MockPermissionService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testCheckMicrophonePermission_returnsMockStatus() {
        sut.mockStatus = .granted
        XCTAssertEqual(sut.checkMicrophonePermission(), .granted)
        
        sut.mockStatus = .denied
        XCTAssertEqual(sut.checkMicrophonePermission(), .denied)
        
        sut.mockStatus = .notDetermined
        XCTAssertEqual(sut.checkMicrophonePermission(), .notDetermined)
    }
    
    func testRequestMicrophonePermission_whenShouldSucceed_returnsMockStatus() async throws {
        sut.mockStatus = .granted
        sut.shouldThrowError = false
        
        let result = try await sut.requestMicrophonePermission()
        XCTAssertEqual(result, .granted)
    }
    
    func testRequestMicrophonePermission_whenShouldThrowError_throwsExpectedError() async {
        sut.shouldThrowError = true
        sut.errorToThrow = AppError.permissionError(.microphoneDenied)
        
        do {
            _ = try await sut.requestMicrophonePermission()
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            if case .permissionError(.microphoneDenied) = error {
                // Success - correct error thrown
            } else {
                XCTFail("Expected AppError.permissionError(.microphoneDenied), got \(error)")
            }
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }
    
    func testRequestMicrophonePermission_whenShouldThrowRestricted_throwsRestrictedError() async {
        sut.shouldThrowError = true
        sut.errorToThrow = AppError.permissionError(.microphoneRestricted)
        
        do {
            _ = try await sut.requestMicrophonePermission()
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            if case .permissionError(.microphoneRestricted) = error {
                // Success - correct error thrown
            } else {
                XCTFail("Expected AppError.permissionError(.microphoneRestricted), got \(error)")
            }
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }
}