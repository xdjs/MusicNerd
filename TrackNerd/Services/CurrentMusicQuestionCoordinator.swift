import Foundation

@MainActor
final class CurrentMusicQuestionCoordinator: CurrentMusicQuestionCoordinating {
  private let playbackResolver: any CurrentPlaybackResolving
  private let identityResolver: any MusicIdentityResolving
  private let knowledgeService: any MusicKnowledgeServing

  init(
    playbackResolver: any CurrentPlaybackResolving,
    identityResolver: any MusicIdentityResolving,
    knowledgeService: any MusicKnowledgeServing
  ) {
    self.playbackResolver = playbackResolver
    self.identityResolver = identityResolver
    self.knowledgeService = knowledgeService
  }

  func overview(scope: KnowledgeScope) async throws -> KnowledgeAnswer {
    try Task.checkCancellation()
    let playbackItem = try await playbackResolver.currentItem()
    try Task.checkCancellation()
    let identity = try await identityResolver.resolve(playbackItem)
    try Task.checkCancellation()
    let answer = try await knowledgeService.overview(for: identity, scope: scope)
    try Task.checkCancellation()
    return answer
  }
}
