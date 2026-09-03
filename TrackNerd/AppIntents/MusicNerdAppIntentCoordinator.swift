import Foundation

@MainActor
final class MusicNerdAppIntentCoordinator: CurrentMusicQuestionCoordinating {
  private let productionCoordinator: any CurrentMusicQuestionCoordinating

  #if DEBUG
  private var testScenario: ExplainCurrentArtistTestScenario?
  #endif

  init(productionCoordinator: any CurrentMusicQuestionCoordinating) {
    self.productionCoordinator = productionCoordinator
  }

  func overview(scope: KnowledgeScope) async throws -> KnowledgeAnswer {
    #if DEBUG
    if let testScenario {
      return try testScenario.result(scope: scope)
    }
    #endif

    return try await productionCoordinator.overview(scope: scope)
  }

  #if DEBUG
  func configureTestScenario(_ scenario: ExplainCurrentArtistTestScenario) {
    testScenario = scenario
  }

  func resetTestScenario() {
    testScenario = nil
  }
  #endif
}
