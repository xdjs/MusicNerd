#if DEBUG
import AppIntents

struct ConfigureExplainCurrentArtistTestScenarioIntent: AppIntent {
  static let title: LocalizedStringResource =
    "Configure Explain Current Artist Test Scenario"
  static let description = IntentDescription(
    "Configures deterministic debug behavior for App Intents tests."
  )
  static let isDiscoverable = false

  @Parameter(title: "Scenario")
  var scenario: String

  init() {}

  init(scenario: String) {
    self.scenario = scenario
  }

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let message: String
    if
      let scenario = ExplainCurrentArtistTestScenario(rawValue: scenario),
      await MusicNerdAppIntentDependencies.configureTestScenario(scenario)
    {
      message = "Configured \(scenario.rawValue)."
    } else {
      message = "The requested test scenario is unavailable."
    }

    return .result(value: message, dialog: IntentDialog("\(message)"))
  }
}
#endif
