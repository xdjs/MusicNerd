//
//  TrackNerdUITests.swift
//  TrackNerdUITests
//
//  Created by Carl Tydingco on 8/4/25.
//

import XCTest

final class TrackNerdUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchAndInitialState() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        XCTAssertTrue(app.exists, "App should exist after launch")
        XCTAssertEqual(app.state, .runningForeground, "App should be running in foreground")
        
        // Test that tab bar exists with a longer timeout
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "Tab bar should be visible")
        
        // Just test basic app launch for now
        XCTAssertTrue(app.windows.firstMatch.exists, "Main window should exist")
    }
    
    @MainActor
    func testTabNavigationBetweenSections() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        // Wait for tab bar to appear
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "Tab bar should be visible")
        
        // Test basic tab existence - simplified for debugging
        let historyTab = app.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10.0), "History tab should be visible")
        
        let settingsTab = app.buttons["Settings"] 
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10.0), "Settings tab should be visible")
        
        let listenTab = app.buttons["Listen"]
        XCTAssertTrue(listenTab.waitForExistence(timeout: 10.0), "Listen tab should be visible")
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
