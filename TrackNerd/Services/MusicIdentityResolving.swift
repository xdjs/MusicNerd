import Foundation

@MainActor
protocol MusicIdentityResolving: Sendable {
  func resolve(_ item: CurrentPlaybackItem) async throws -> MusicIdentity
}
