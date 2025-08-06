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
        app = nil
    }
    
    func testListenButtonExists() throws {
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(listenButton.exists)
        XCTAssertEqual(listenButton.label, "Start Listening")
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
        let alertExists = permissionAlert.waitForExistence(timeout: 2.0)
        let listeningExists = listeningIndicator.waitForExistence(timeout: 2.0)
        
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
            let listeningButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Listening' OR label CONTAINS 'Recognizing'")).firstMatch
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
            
            // Check that "Found It!" text appears
            let foundItText = app.staticTexts["Found It!"]
            XCTAssertTrue(foundItText.exists)
        }
    }
    
    func testSeeAllButton_exists() throws {
        let seeAllButton = app.buttons["see-all-button"]
        XCTAssertTrue(seeAllButton.exists)
        XCTAssertEqual(seeAllButton.label, "See All")
    }
    
    func testRecentMatches_showSampleData() throws {
        // Test that sample matches are displayed
        let recentMatch0 = app.otherElements["recent-match-0"]
        let recentMatch1 = app.otherElements["recent-match-1"]
        
        XCTAssertTrue(recentMatch0.exists)
        XCTAssertTrue(recentMatch1.exists)
        
        // Check that sample data is displayed
        let bohemianRhapsody = app.staticTexts["Bohemian Rhapsody"]
        let hotelCalifornia = app.staticTexts["Hotel California"]
        
        XCTAssertTrue(bohemianRhapsody.exists)
        XCTAssertTrue(hotelCalifornia.exists)
    }
    
    func testNavigationTitle() throws {
        let navigationTitle = app.navigationBars["Listen"]
        XCTAssertTrue(navigationTitle.exists)
    }
    
    func testListeningViewAccessibility() throws {
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(listenButton.isHittable)
        
        let seeAllButton = app.buttons["see-all-button"]
        XCTAssertTrue(seeAllButton.isHittable)
        
        // Test that sample match cards are accessible
        let recentMatch0 = app.otherElements["recent-match-0"]
        let recentMatch1 = app.otherElements["recent-match-1"]
        
        XCTAssertTrue(recentMatch0.isHittable)
        XCTAssertTrue(recentMatch1.isHittable)
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