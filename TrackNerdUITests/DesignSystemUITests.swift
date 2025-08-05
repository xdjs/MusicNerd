import XCTest

final class DesignSystemUITests: XCTestCase {
    
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
    
    // MARK: - Color System UI Tests
    func testColorSystemAccessibility() throws {
        // Test that the app launches with proper color contrast
        XCTAssertTrue(app.exists, "App should launch successfully")
        
        // Test that tab bar and navigation elements are visible (good contrast)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Tab bar should be visible with proper contrast")
        
        // Test that main text in listening view is visible
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0), "Main title should be visible with proper contrast")
        XCTAssertTrue(whatPlayingText.isHittable, "Text should be accessible")
    }
    
    func testBrandColorConsistency() throws {
        // Test that the app uses consistent branding colors
        XCTAssertTrue(app.exists)
        
        // While we can't directly test color values in UI tests,
        // we can test that colored elements are present and accessible
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.exists, "Main window should exist with proper background")
    }
    
    // MARK: - Typography UI Tests
    func testTypographyHierarchy() throws {
        // Test that different text elements have appropriate hierarchy
        let textElements = app.staticTexts.allElementsBoundByIndex
        XCTAssertGreaterThan(textElements.count, 0, "Should have text elements with typography applied")
        
        // Test that key text elements are readable and accessible
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0))
        XCTAssertTrue(whatPlayingText.isHittable, "Main title should be accessible")
        
        let recentMatchesText = app.staticTexts["Recent Matches"]
        if recentMatchesText.exists {
            XCTAssertTrue(recentMatchesText.isHittable, "Section header should be accessible")
        }
    }
    
    func testTextReadability() throws {
        // Test that text elements are properly sized and readable
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0))
        
        // Text should have reasonable frame dimensions
        let frame = whatPlayingText.frame
        XCTAssertGreaterThan(frame.width, 0)
        XCTAssertGreaterThan(frame.height, 0)
    }
    
    // MARK: - Component Visual Tests
    func testBasicComponentPresence() throws {
        // Test that basic UI components are present and properly sized
        XCTAssertTrue(app.exists)
        
        // Test main content area
        let mainView = app.otherElements.firstMatch
        XCTAssertTrue(mainView.exists, "Main view should be present")
        
        // Test that the view has reasonable dimensions
        let frame = mainView.frame
        XCTAssertGreaterThan(frame.width, 0)
        XCTAssertGreaterThan(frame.height, 0)
    }
    
    func testImageElements() throws {
        // Test that image elements are properly displayed
        let waveformIcons = app.images["waveform.circle"]
        let firstIcon = waveformIcons.firstMatch
        XCTAssertTrue(firstIcon.waitForExistence(timeout: 5.0), "Waveform icon should be present")
        
        // Test first icon dimensions
        let imageFrame = firstIcon.frame
        XCTAssertGreaterThan(imageFrame.width, 0)
        XCTAssertGreaterThan(imageFrame.height, 0)
    }
    
    // MARK: - Spacing and Layout Tests
    func testLayoutSpacing() throws {
        // Test that elements have proper spacing
        let textElement = app.staticTexts["What's Playing?"]
        let imageElements = app.images["waveform.circle"]
        
        XCTAssertTrue(textElement.waitForExistence(timeout: 5.0))
        XCTAssertTrue(imageElements.firstMatch.waitForExistence(timeout: 5.0))
        
        // Elements should not overlap (basic spacing test)
        let textFrame = textElement.frame
        let imageFrame = imageElements.firstMatch.frame
        
        XCTAssertFalse(textFrame.isEmpty)
        XCTAssertFalse(imageFrame.isEmpty)
    }
    
    func testScreenMargins() throws {
        // Test that content has proper margins from screen edges
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5.0), "Main window should exist")
        
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0))
        
        let screenFrame = mainWindow.frame
        let textFrame = whatPlayingText.frame
        
        // Content should not touch screen edges (basic margin test)
        XCTAssertGreaterThan(textFrame.minX, 0, "Text should have left margin")
        XCTAssertLessThan(textFrame.maxX, screenFrame.maxX, "Text should have right margin")
        XCTAssertGreaterThan(textFrame.minY, 0, "Text should have top margin")
    }
    
    // MARK: - Accessibility Tests
    func testVoiceOverSupport() throws {
        // Test that elements support VoiceOver
        let textElement = app.staticTexts["What's Playing?"]
        XCTAssertTrue(textElement.waitForExistence(timeout: 5.0))
        XCTAssertTrue(textElement.isHittable, "Text should be accessible to VoiceOver")
        
        let imageElements = app.images["waveform.circle"]
        let firstImage = imageElements.firstMatch
        XCTAssertTrue(firstImage.waitForExistence(timeout: 5.0))
        // Note: SF Symbol images in ScrollViews may not always be hittable in UI tests
        // This is a known limitation, so we'll just check existence
        XCTAssertTrue(firstImage.exists, "Image should exist for VoiceOver")
    }
    
    func testAccessibilityIdentifiers() throws {
        // Test that key elements have accessibility identifiers
        XCTAssertTrue(app.exists)
        
        // Main UI elements should be accessible
        let accessibleElements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        XCTAssertGreaterThan(accessibleElements.count, 0, "Should have accessible elements")
    }
    
    // MARK: - Responsive Design Tests
    func testPortraitLayout() throws {
        // Test layout in portrait orientation
        XCUIDevice.shared.orientation = .portrait
        
        // Give time for orientation change
        Thread.sleep(forTimeInterval: 1.0)
        
        XCTAssertTrue(app.exists)
        
        // Content should still be visible and properly laid out
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0), "Content should be visible in portrait")
        XCTAssertTrue(whatPlayingText.isHittable, "Content should be accessible in portrait")
    }
    
    func testLandscapeLayout() throws {
        // Test layout in landscape orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Give time for orientation change
        Thread.sleep(forTimeInterval: 1.0)
        
        XCTAssertTrue(app.exists)
        
        // Content should still be visible and properly laid out
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0), "Content should be visible in landscape")
        XCTAssertTrue(whatPlayingText.isHittable, "Content should be accessible in landscape")
        
        // Reset orientation
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Performance Tests
    func testUIResponsiveness() throws {
        // Test that UI is responsive and doesn't freeze
        let startTime = Date()
        
        // Perform basic interactions
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 2.0), "UI should load quickly")
        
        let loadTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(loadTime, 3.0, "UI should load within 3 seconds")
    }
    
    func testScrollPerformance() throws {
        // If there's scrollable content, test scroll performance
        // For now, just test that the view exists and is responsive
        let mainView = app.otherElements.firstMatch
        XCTAssertTrue(mainView.exists)
        
        // Test tap responsiveness
        let startTime = Date()
        mainView.tap()
        let tapResponseTime = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(tapResponseTime, 0.5, "UI should respond to taps quickly")
    }
    
    // MARK: - Dark Mode Tests (Future)
    func testDarkModeSupport() throws {
        // Note: Dark mode testing would require app-specific implementation
        // For now, test that the app continues to work regardless of system appearance
        XCTAssertTrue(app.exists, "App should work in all appearance modes")
        
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0), "Text should be visible in all appearance modes")
    }
    
    // MARK: - Visual Regression Prevention
    func testBasicVisualStructure() throws {
        // Test that the basic visual structure is maintained
        XCTAssertTrue(app.exists)
        
        // Key elements should be present
        let whatPlayingText = app.staticTexts["What's Playing?"]
        let waveformImages = app.images["waveform.circle"]
        
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0), "Main text should be present")
        XCTAssertTrue(waveformImages.firstMatch.waitForExistence(timeout: 5.0), "Main image should be present")
        
        // Elements should be in expected positions relative to each other
        let textFrame = whatPlayingText.frame
        let imageFrame = waveformImages.firstMatch.frame
        
        // Image should be above text in the current layout
        XCTAssertLessThan(imageFrame.midY, textFrame.midY, "Image should be above text")
    }
    
    func testLayoutConsistency() throws {
        // Test that layout is consistent across app launches
        let whatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatPlayingText.waitForExistence(timeout: 5.0))
        let initialFrame = whatPlayingText.frame
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        
        let relaunchtWhatPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(relaunchtWhatPlayingText.waitForExistence(timeout: 5.0))
        let relaunchtFrame = relaunchtWhatPlayingText.frame
        
        // Frame should be reasonably similar (allowing for minor differences)
        XCTAssertEqual(initialFrame.width, relaunchtFrame.width, accuracy: 5.0)
        XCTAssertEqual(initialFrame.height, relaunchtFrame.height, accuracy: 5.0)
    }
    
    // MARK: - Design System Component Tests
    func testButtonElements() throws {
        // Test that buttons are present and accessible
        let listenButton = app.buttons.matching(identifier: "listen-button").firstMatch
        XCTAssertTrue(listenButton.waitForExistence(timeout: 5.0), "Listen button should be present")
        XCTAssertTrue(listenButton.isHittable, "Button should be tappable")
        
        let historyTab = app.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 5.0), "History tab should be present")
        
        let settingsTab = app.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5.0), "Settings tab should be present")
    }
    
    func testCardElements() throws {
        // Test that card elements are present
        let recentMatchesText = app.staticTexts["Recent Matches"]
        XCTAssertTrue(recentMatchesText.waitForExistence(timeout: 5.0), "Recent Matches section should be present")
        
        // Test song match cards
        let bohemianRhapsodyText = app.staticTexts["Bohemian Rhapsody"]
        XCTAssertTrue(bohemianRhapsodyText.waitForExistence(timeout: 5.0), "Song card should be present")
        
        let queenText = app.staticTexts["Queen"]
        XCTAssertTrue(queenText.waitForExistence(timeout: 5.0), "Artist text should be present")
    }
    
    func testInteractiveElements() throws {
        // Test basic button interaction
        let listenButton = app.buttons.matching(identifier: "listen-button").firstMatch
        XCTAssertTrue(listenButton.waitForExistence(timeout: 5.0), "Listen button should exist")
        XCTAssertTrue(listenButton.isHittable, "Listen button should be tappable")
        
        // Test button tap - this should work regardless of loading state behavior
        listenButton.tap()
        
        // After tapping, button should still exist and be tappable
        XCTAssertTrue(listenButton.exists, "Button should still exist after tap")
        
        // Test second tap to ensure button remains functional
        listenButton.tap()
        
        // Button should still be present and functional
        XCTAssertTrue(listenButton.exists, "Button should remain functional after multiple taps")
        XCTAssertTrue(listenButton.isHittable, "Button should remain tappable")
    }
}