import Foundation

@MainActor
protocol MusicKnowledgeServing: Sendable {
  func overview(
    for identity: MusicIdentity,
    scope: KnowledgeScope
  ) async throws -> KnowledgeAnswer
}
