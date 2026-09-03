import Foundation

@MainActor
protocol CurrentMusicQuestionCoordinating: Sendable {
  func overview(scope: KnowledgeScope) async throws -> KnowledgeAnswer
}
