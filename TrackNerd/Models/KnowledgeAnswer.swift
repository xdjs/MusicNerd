import Foundation

struct KnowledgeAnswer: Equatable, Sendable {
  enum Source: String, Equatable, Sendable {
    case musicNerdAPI
    case cache
    case staleCache
  }

  let scope: KnowledgeScope
  let identity: MusicIdentity
  let spokenText: String
  let source: Source

  func rebased(
    on identity: MusicIdentity,
    source: Source
  ) -> KnowledgeAnswer {
    KnowledgeAnswer(
      scope: scope,
      identity: identity,
      spokenText: spokenText,
      source: source
    )
  }
}
