//
//  MusicNerdUITests.swift
//  MusicNerdUITests
//
//  Created by Carl Tydingco on 8/4/25.
//

import XCTest

final class MusicNerdUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - UI Test Helpers
    
    /// Waits for an element to exist with adaptive timeout based on system performance
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
    
    /// Waits for app to fully launch and UI to stabilize
    private func waitForAppLaunch(_ app: XCUIApplication) -> Bool {
        // Wait for app state first
        let appRunningPredicate = NSPredicate(format: "state == %d", XCUIApplication.State.runningForeground.rawValue)
        let appExpectation = XCTNSPredicateExpectation(predicate: appRunningPredicate, object: app)
        
        if XCTWaiter().wait(for: [appExpectation], timeout: 15.0) != .completed {
            XCTFail("App failed to reach running state within 15 seconds")
            return false
        }
        
        // Wait for main window to be available
        if !waitForElement(app.windows.firstMatch, description: "Main window") {
            return false
        }
        
        // Wait for tab bar to stabilize (indicates UI is ready)
        return waitForElement(app.tabBars.firstMatch, description: "Tab bar", timeout: 15.0)
    }

    @MainActor
    func testAppLaunchAndInitialState() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        // Use improved launch waiting
        XCTAssertTrue(waitForAppLaunch(app), "App should launch successfully")
        
        // Test basic app state assertions
        XCTAssertTrue(app.exists, "App should exist after launch")
        XCTAssertEqual(app.state, .runningForeground, "App should be running in foreground")
        
        // Main window should be available (already verified in waitForAppLaunch)
        XCTAssertTrue(app.windows.firstMatch.exists, "Main window should exist")
    }
    
    @MainActor
    func testTabNavigationBetweenSections() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        // Use improved launch waiting
        XCTAssertTrue(waitForAppLaunch(app), "App should launch successfully")
        
        // Test basic tab existence using helper method
        let historyTab = app.buttons["History"]
        XCTAssertTrue(waitForElement(historyTab, description: "History tab"), "History tab should be visible")
        
        let settingsTab = app.buttons["Settings"] 
        XCTAssertTrue(waitForElement(settingsTab, description: "Settings tab"), "Settings tab should be visible")
        
        let listenTab = app.buttons["Listen"]
        XCTAssertTrue(waitForElement(listenTab, description: "Listen tab"), "Listen tab should be visible")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments.append("--uitesting")
            app.launch()
        }
    }
}
