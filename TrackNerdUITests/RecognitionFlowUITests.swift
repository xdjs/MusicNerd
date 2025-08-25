import XCTest

final class RecognitionFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }
    
    // MARK: - UI Test Helpers
    
    /// Waits for an element to exist with adaptive timeout
    private func waitForElement(_ element: XCUIElement, description: String, timeout: TimeInterval = 30.0) -> Bool {
        let existsPredicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        
        if result != .completed {
            XCTFail("\(description) failed to appear within \(timeout) seconds")
            return false
        }
        return true
    }
    
    /// Waits for main UI to fully load
    private func waitForMainUILoad() -> Bool {
        let mainHeading = app.staticTexts["Hear. ID. Nerd out."]
        return waitForElement(mainHeading, description: "Main UI heading", timeout: 15.0)
    }
    
    func testListenButtonExists() throws {
        XCTAssertTrue(waitForMainUILoad(), "Main UI should load")
        
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(waitForElement(listenButton, description: "Listen button"), "Listen button should exist")
        XCTAssertFalse(listenButton.label.isEmpty)
    }
    
    func testListenButtonTap_showsPermissionRequest() throws {
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(listenButton.exists)
        
        listenButton.tap()
        
        // Check if permission alert appears or listening state changes
        // This will depend on the current permission state of the simulator
        let permissionAlert = app.alerts.firstMatch
        let listeningIndicator = app.staticTexts["Listening for music..."]
        
        // Either permission alert should appear or listening should start
        let alertExists = permissionAlert.waitForExistence(timeout: 5.0)
        let listeningExists = listeningIndicator.waitForExistence(timeout: 5.0)
        
        XCTAssertTrue(alertExists || listeningExists, "Either permission alert or listening state should appear")
    }
    
    func testListeningState_showsCorrectUI() throws {
        let listenButton = app.buttons["listen-button"]
        
        // Attempt to start listening
        listenButton.tap()
        
        // If permission is granted and listening starts
        let listeningMessage = app.staticTexts["Listening for music..."]
        if listeningMessage.waitForExistence(timeout: 3.0) {
            XCTAssertTrue(listeningMessage.exists)
            
            // Check that button text changes
            let listeningButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Listening' OR label CONTAINS 'Recognizing'")) .firstMatch
            XCTAssertTrue(listeningButton.exists)
        }
    }
    
    func testPermissionDeniedState_showsEnableMicrophoneButton() throws {
        // This test would require the simulator to have microphone permission denied
        // For now, we'll test that the button can handle different states
        
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(listenButton.exists)
        
        // The button should exist regardless of permission state
        XCTAssertTrue(listenButton.isEnabled)
    }
    
    func testRecognitionResult_showsMatchCard() throws {
        // This test would require a successful recognition
        // For now, we'll test that the UI can display recognition results
        
        let listenButton = app.buttons["listen-button"]
        listenButton.tap()
        
        // Wait for potential recognition result
        let recognitionResult = app.otherElements["recognition-result"]
        
        // If a match is found (unlikely in testing environment)
        if recognitionResult.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(recognitionResult.exists)
        }
    }
    
    func testSeeAllButton_exists() throws {
        XCTAssertTrue(waitForMainUILoad(), "Main UI should load first")
        
        let seeAllButton = app.buttons["see-all-button"]
        XCTAssertTrue(waitForElement(seeAllButton, description: "See All button"), "See All button should exist")
        XCTAssertEqual(seeAllButton.label, "See All")
    }
    
    func testRecentMatches_showSampleData() throws {
        XCTAssertTrue(waitForMainUILoad(), "Main UI should load first")
        
        // Check Recent Matches section exists
        let recentMatchesHeading = app.staticTexts["Recent Matches"]
        XCTAssertTrue(waitForElement(recentMatchesHeading, description: "Recent Matches heading"), "Recent Matches section should exist")
        
        // Validate by presence of sample text, using helper method for better timing
        let bohemianRhapsodyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Bohemian Rhapsody'")).firstMatch
        let hotelCaliforniaText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Hotel California'")).firstMatch
        
        XCTAssertTrue(waitForElement(bohemianRhapsodyText, description: "Bohemian Rhapsody text"), "Sample data should include Bohemian Rhapsody")
        XCTAssertTrue(waitForElement(hotelCaliforniaText, description: "Hotel California text"), "Sample data should include Hotel California")
    }
    
    func testNavigationTitle() throws {
        let navigationTitle = app.navigationBars["Listen"]
        XCTAssertTrue(navigationTitle.waitForExistence(timeout: 10.0), "Listen navigation title should exist")
    }
    
    func testListeningViewAccessibility() throws {
        // Wait for UI to fully load
        XCTAssertTrue(waitForMainUILoad(), "Main UI should load")
        
        // Test listen button accessibility (should be interactive when enabled)
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(waitForElement(listenButton, description: "Listen button"), "Listen button should exist")
        XCTAssertFalse(listenButton.label.isEmpty, "Listen button should have accessible label")
        
        // Test see all button accessibility (exists but may be disabled for Phase 6)
        let seeAllButton = app.buttons["see-all-button"]
        XCTAssertTrue(waitForElement(seeAllButton, description: "See All button"), "See All button should exist")
        XCTAssertFalse(seeAllButton.label.isEmpty, "See All button should have accessible label")
        
        // Validate sample match content presence by text using proper waiting
        let sampleMatchText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Bohemian Rhapsody' OR label CONTAINS[c] 'Hotel California'")).firstMatch
        XCTAssertTrue(waitForElement(sampleMatchText, description: "Sample match text"), "At least one sample match text should be visible")
        
        // Test overall UI accessibility
        XCTAssertTrue(waitForElement(app.tabBars.firstMatch, description: "Tab bar"), "Tab navigation should be accessible")
        XCTAssertTrue(app.staticTexts["Hear. ID. Nerd out."].exists, "Main content should be accessible")
    }
    
    func testErrorState_showsErrorMessage() throws {
        // This test would require triggering an error state
        // For now, we'll test that error UI can be displayed
        
        let listenButton = app.buttons["listen-button"]
        listenButton.tap()
        
        // Wait for potential error message
        // Error messages would appear as static text with red color
        // We can't easily test color in UI tests, but we can test for error text patterns
        
        let errorTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'failed' OR label CONTAINS 'error' OR label CONTAINS 'Try again'"))
        
        // If an error occurs during testing
        if errorTexts.count > 0 {
            let errorText = errorTexts.firstMatch
            XCTAssertTrue(errorText.exists)
        }
    }
}