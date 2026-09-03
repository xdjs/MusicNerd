#if DEBUG
import AppIntents

struct ResetExplainCurrentArtistTestScenarioIntent: AppIntent {
  static let title: LocalizedStringResource =
    "Reset Explain Current Artist Test Scenario"
  static let description = IntentDescription(
    "Restores production behavior after App Intents tests."
  )
  static let isDiscoverable = false

  init() {}

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let didReset = await MusicNerdAppIntentDependencies.resetTestScenario()
    let message = didReset
      ? "Reset the Explain Current Artist test scenario."
      : "The Explain Current Artist test scenario was already reset."
    return .result(value: message, dialog: IntentDialog("\(message)"))
  }
}
#endif
