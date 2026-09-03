import AppIntentsTesting
import XCTest

@MainActor
final class ExplainCurrentArtistIntentIntegrationTests: XCTestCase {
  private static let appBundleIdentifier = "com.xdjs.musicnerd"

  private let app = XCUIApplication()
  private var definitions: IntentDefinitions!

  override func setUp() async throws {
    continueAfterFailure = false

    app.launchArguments = ["--uitesting", "--app-intents-testing"]
    app.launch()

    definitions = IntentDefinitions(
      bundleIdentifier: Self.appBundleIdentifier
    )
    try await resetScenario()
  }

  override func tearDown() async throws {
    try await resetScenario()
    app.terminate()
    definitions = nil
  }

  func testExplainCurrentArtistIntentIsDiscoverable() throws {
    let definition = explainCurrentArtistDefinition
    let intent = definition.makeIntent()

    XCTAssertEqual(definition.bundleIdentifier, Self.appBundleIdentifier)
    XCTAssertEqual(definition.identifier, "ExplainCurrentArtistIntent")
    XCTAssertEqual(intent.bundleIdentifier, Self.appBundleIdentifier)
    XCTAssertEqual(intent.identifier, definition.identifier)
  }

  func testExplainCurrentArtistIntentReturnsGroundedSuccessDialog() async throws {
    try await configureScenario("success")

    let result = try await explainCurrentArtistDefinition
      .makeIntent()
      .run()
    let message: String = try result.value

    assertDialogShape(
      message,
      equals: "Test Artist is a Music Nerd test artist."
    )
  }

  func testExplainCurrentArtistIntentReturnsFocusedFailureDialogs() async throws {
    let cases = [
      (
        scenario: "authorizationDenied",
        message: "Allow Apple Music access for Music Nerd in Settings."
      ),
      (
        scenario: "noPlayback",
        message: "Play something in Apple Music, then try again."
      ),
      (
        scenario: "unsupportedContent",
        message: "That type of Apple Music item isn't supported yet."
      ),
      (
        scenario: "ambiguousIdentity",
        message: "Music Nerd found multiple possible artists and won't guess."
      ),
      (
        scenario: "offline",
        message: "Music Nerd is offline. Reconnect and try again."
      ),
      (
        scenario: "noKnowledge",
        message: "Music Nerd doesn't have artist details yet."
      )
    ]

    for testCase in cases {
      try await configureScenario(testCase.scenario)

      let result = try await explainCurrentArtistDefinition
        .makeIntent()
        .run()
      let message: String = try result.value

      assertDialogShape(message, equals: testCase.message)
    }
  }

  private var explainCurrentArtistDefinition: AppIntentDefinition {
    definitions.intents["ExplainCurrentArtistIntent"]
  }

  private func configureScenario(_ scenario: String) async throws {
    let result = try await definitions.intents[
      "ConfigureExplainCurrentArtistTestScenarioIntent"
    ]
    .makeIntent(scenario: scenario)
    .run()
    let message: String = try result.value

    XCTAssertEqual(message, "Configured \(scenario).")
  }

  private func resetScenario() async throws {
    guard definitions != nil else { return }

    _ = try await definitions.intents[
      "ResetExplainCurrentArtistTestScenarioIntent"
    ]
    .makeIntent()
    .run()
  }

  private func assertDialogShape(
    _ message: String,
    equals expectedMessage: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    // The production intent uses this returned value as its IntentDialog source.
    // AppIntentsTesting exposes the result value but not the rendered dialog.
    XCTAssertEqual(message, expectedMessage, file: file, line: line)
    XCTAssertFalse(message.isEmpty, file: file, line: line)
    XCTAssertLessThanOrEqual(message.count, 600, file: file, line: line)
    XCTAssertTrue(
      message.hasSuffix(".") || message.hasSuffix("!") || message.hasSuffix("?"),
      file: file,
      line: line
    )
  }
}
