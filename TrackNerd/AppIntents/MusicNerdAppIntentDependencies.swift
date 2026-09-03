import AppIntents
import Foundation

@MainActor
enum MusicNerdAppIntentDependencies {
  nonisolated static let currentMusicQuestionCoordinatorKey =
    "xyz.musicnerd.app-intents.current-music-question-coordinator"

  private static var coordinator: MusicNerdAppIntentCoordinator?

  static func register(
    coordinator productionCoordinator: any CurrentMusicQuestionCoordinating
  ) {
    guard coordinator == nil else { return }

    let coordinator = MusicNerdAppIntentCoordinator(
      productionCoordinator: productionCoordinator
    )
    self.coordinator = coordinator
    AppDependencyManager.shared.add(
      key: currentMusicQuestionCoordinatorKey,
      dependency: coordinator as any CurrentMusicQuestionCoordinating
    )
  }

  #if DEBUG
  static func configureTestScenario(
    _ scenario: ExplainCurrentArtistTestScenario
  ) -> Bool {
    guard let coordinator else { return false }
    coordinator.configureTestScenario(scenario)
    return true
  }

  static func resetTestScenario() -> Bool {
    guard let coordinator else { return false }
    coordinator.resetTestScenario()
    return true
  }
  #endif
}
