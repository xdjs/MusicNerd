#if DEBUG
import XCTest

final class CurrentPlaybackDiagnosticUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments.append("--uitesting")
    app.launch()
  }

  override func tearDownWithError() throws {
    app.terminate()
    app = nil
  }

  func testDebugSettingsLinkOpensReadOnlyDiagnostic() {
    let settingsTab = app.tabBars.buttons["Settings"]
    XCTAssertTrue(settingsTab.waitForExistence(timeout: 10))
    settingsTab.tap()

    let diagnosticLink = app.descendants(matching: .any)["current-playback-diagnostic-link"]

    for _ in 0..<6 where !diagnosticLink.isHittable {
      app.swipeUp()
    }

    XCTAssertTrue(diagnosticLink.isHittable)
    diagnosticLink.tap()

    XCTAssertTrue(app.navigationBars["Current Playback"].waitForExistence(timeout: 5))
    XCTAssertTrue(
      app.descendants(matching: .any)["current-playback-capture"].waitForExistence(timeout: 5)
    )
    let privacyFooter = app.staticTexts[
      "Results remain on this screen only. No backend, persistence, or analytics are used."
    ]
    XCTAssertTrue(privacyFooter.exists)
  }
}
#endif
