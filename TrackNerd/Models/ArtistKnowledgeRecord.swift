import Foundation

struct ArtistKnowledgeRecord: Equatable, Sendable {
  let artistID: String
  let artistName: String
  let biography: String?
  let facts: [String]
}
