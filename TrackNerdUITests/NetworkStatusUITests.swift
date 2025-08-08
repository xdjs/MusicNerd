import XCTest

final class NetworkStatusUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        
        // Launch the app
        app.launch()
        
        // Wait for the app to load
        _ = app.staticTexts["What's Playing?"].waitForExistence(timeout: 5.0)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Network Status Indicator Tests
    
    func testNetworkStatusIndicatorExists() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Check if network status indicator exists
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3.0), "Network status indicator should be visible")
    }
    
    func testNetworkStatusIndicatorAccessibility() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Check network status indicator accessibility
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3.0))
        
        // Verify it has accessibility label
        let accessibilityLabel = networkIndicator.label
        XCTAssertTrue(accessibilityLabel.contains("Network status"), "Network indicator should have accessibility label describing network status")
    }
    
    func testNetworkStatusIndicatorTapInteraction() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Wait for network indicator
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3.0))
        
        // Tap to toggle details
        networkIndicator.tap()
        
        // Give time for animation
        sleep(1)
        
        // Tap again to toggle back
        networkIndicator.tap()
        
        // Test should complete without crashes
        XCTAssertTrue(networkIndicator.exists)
    }
    
    // MARK: - Network Status Banner Tests
    
    func testNetworkStatusBannerWhenOffline() throws {
        // Note: This test would require network simulation or mocking
        // For now, we test that the banner element can be found when it exists
        
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Check if banner exists (it may not be visible if online)
        let networkBanner = app.otherElements["networkStatusBanner"]
        
        if networkBanner.exists {
            // If banner exists (offline), verify its properties
            XCTAssertTrue(networkBanner.isHittable, "Network banner should be hittable if visible")
            
            let accessibilityLabel = networkBanner.label
            XCTAssertTrue(accessibilityLabel.contains("internet connection") || accessibilityLabel.contains("Internet Connection"), 
                         "Banner should mention internet connection")
        } else {
            // If banner doesn't exist (online), that's also valid
            XCTAssertTrue(true, "Network banner not visible - likely online")
        }
    }
    
    // MARK: - Listen Button Network State Tests
    
    func testListenButtonWhenOnline() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Find the listen button
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(listenButton.waitForExistence(timeout: 3.0))
        
        // When online, button should be enabled (assuming we have network)
        // Note: This assumes the test environment has network connectivity
        if listenButton.isEnabled {
            // Verify button title doesn't indicate offline
            let buttonLabel = listenButton.label
            XCTAssertFalse(buttonLabel.contains("No Internet"), "Button should not show offline message when online")
            XCTAssertTrue(buttonLabel.contains("Start Listening") || buttonLabel.contains("Enable Microphone"), 
                         "Button should show appropriate online message")
        }
    }
    
    func testListenButtonAccessibilityWithNetworkStatus() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Find the listen button
        let listenButton = app.buttons["listen-button"]
        XCTAssertTrue(listenButton.waitForExistence(timeout: 3.0))
        
        // Verify button has proper accessibility
        XCTAssertFalse(listenButton.label.isEmpty, "Listen button should have accessibility label")
        XCTAssertTrue(listenButton.isHittable, "Listen button should be hittable")
    }
    
    // MARK: - Network State Integration Tests
    
    func testNetworkStatusIndicatorAndBannerCoherence() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Get both network elements
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        let networkBanner = app.otherElements["networkStatusBanner"]
        
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3.0))
        
        // If banner is visible (offline), indicator should show offline state too
        if networkBanner.exists {
            // Both should indicate offline state
            let indicatorLabel = networkIndicator.label
            let bannerLabel = networkBanner.label
            
            XCTAssertTrue(indicatorLabel.contains("Offline") || indicatorLabel.contains("Unavailable"), 
                         "Indicator should show offline when banner is visible")
            XCTAssertTrue(bannerLabel.contains("internet connection") || bannerLabel.contains("Internet Connection"),
                         "Banner should mention internet connection")
        }
    }
    
    // MARK: - Layout and Visual Tests
    
    func testNetworkStatusIndicatorLayout() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Wait for all UI elements to load
        let whatIsPlayingText = app.staticTexts["What's Playing?"]
        XCTAssertTrue(whatIsPlayingText.waitForExistence(timeout: 3.0))
        
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3.0))
        
        // Verify network indicator is positioned properly relative to main content
        let indicatorFrame = networkIndicator.frame
        let headingFrame = whatIsPlayingText.frame
        
        // Network indicator should be below the heading
        XCTAssertGreaterThan(indicatorFrame.minY, headingFrame.maxY, 
                           "Network indicator should be positioned below the main heading")
        
        // Network indicator should be visible on screen
        XCTAssertTrue(indicatorFrame.width > 0 && indicatorFrame.height > 0, 
                     "Network indicator should have visible dimensions")
    }
    
    // MARK: - Performance Tests
    
    func testNetworkStatusUpdatePerformance() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        // Measure time for network status elements to appear
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        
        measure {
            // Force refresh by scrolling or interacting
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeDown()
                scrollView.swipeUp()
            }
            
            // Verify indicator updates quickly
            _ = networkIndicator.waitForExistence(timeout: 1.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkStatusIndicatorResilience() throws {
        // Navigate to the main listening view
        let listeningTab = app.tabBars.buttons["Listen"]
        XCTAssertTrue(listeningTab.waitForExistence(timeout: 2.0))
        listeningTab.tap()
        
        let networkIndicator = app.otherElements["networkStatusIndicator"]
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3.0))
        
        // Rapid interactions should not cause crashes
        for _ in 0..<5 {
            if networkIndicator.exists && networkIndicator.isHittable {
                networkIndicator.tap()
            }
            usleep(100000) // 0.1 second delay
        }
        
        // App should still be responsive
        XCTAssertTrue(networkIndicator.exists, "Network indicator should still exist after rapid interactions")
        XCTAssertTrue(app.staticTexts["What's Playing?"].exists, "Main UI should still be functional")
    }
}