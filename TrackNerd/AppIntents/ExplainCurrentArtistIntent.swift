import AppIntents
import Foundation

struct ExplainCurrentArtistIntent: AppIntent {
  static let title: LocalizedStringResource = "Tell Me About This Artist"
  static let description = IntentDescription(
    "Get Music Nerd context for the artist currently playing in Apple Music."
  )

  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { .background }

  @Dependency(
    key: MusicNerdAppIntentDependencies.currentMusicQuestionCoordinatorKey
  )
  private var coordinator: any CurrentMusicQuestionCoordinating

  init() {}

  #if DEBUG
  init(testCoordinator: any CurrentMusicQuestionCoordinating) {
    self.init()
    coordinator = testCoordinator
  }
  #endif

  func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
    let message = await responseMessage()
    return .result(value: message, dialog: IntentDialog("\(message)"))
  }

  func responseMessage() async -> String {
    do {
      let answer = try await coordinator.overview(scope: .artist)
      return answer.spokenText
    } catch {
      return ExplainCurrentArtistIntentDialog.message(for: error)
    }
  }
}
