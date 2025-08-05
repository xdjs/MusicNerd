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
        
        let musicNerdText = app.staticTexts["Music Nerd"]
        XCTAssertTrue(musicNerdText.waitForExistence(timeout: 5.0), "Music Nerd title should be visible")
        XCTAssertTrue(musicNerdText.isHittable, "Music Nerd title should be accessible")
        
        let musicIcon = app.images["music.note"]
        XCTAssertTrue(musicIcon.waitForExistence(timeout: 5.0), "Music note icon should be visible")
    }
    
    @MainActor
    func testBasicNavigationStructure() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        XCTAssertTrue(app.windows.firstMatch.exists, "Main window should exist")
        
        let mainView = app.otherElements.firstMatch
        XCTAssertTrue(mainView.exists, "Main view should be present")
        
        XCTAssertGreaterThan(app.children(matching: .any).count, 0, "App should have UI elements")
        
        let accessibilityElements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        XCTAssertGreaterThan(accessibilityElements.count, 0, "App should have accessible elements")
        
        // Test that key sections are present
        let recentMatchesText = app.staticTexts["Recent Matches"]
        XCTAssertTrue(recentMatchesText.waitForExistence(timeout: 5.0), "Recent Matches section should be present")
        
        let actionsText = app.staticTexts["Actions"]
        XCTAssertTrue(actionsText.waitForExistence(timeout: 5.0), "Actions section should be present")
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
