import Foundation

struct CurrentPlaybackItemMapper: Sendable {
  func map(_ sourceItem: CurrentPlaybackSourceItem) throws -> CurrentPlaybackItem {
    switch sourceItem {
    case .song(let sourceItemID, let title, let artistName, let albumTitle):
      return try makeItem(
        sourceItemID: sourceItemID,
        title: title,
        artistName: artistName,
        albumTitle: albumTitle,
        kind: .song
      )
    case .musicVideo(let sourceItemID, let title, let artistName, let albumTitle):
      return try makeItem(
        sourceItemID: sourceItemID,
        title: title,
        artistName: artistName,
        albumTitle: albumTitle,
        kind: .musicVideo
      )
    case .unavailable:
      throw CurrentPlaybackError.itemUnavailable
    case .unsupported:
      throw CurrentPlaybackError.unsupportedItem
    }
  }

  private func makeItem(
    sourceItemID: String,
    title: String,
    artistName: String?,
    albumTitle: String?,
    kind: CurrentPlaybackItem.Kind
  ) throws -> CurrentPlaybackItem {
    let normalizedID = sourceItemID.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !normalizedID.isEmpty, !normalizedTitle.isEmpty else {
      throw CurrentPlaybackError.insufficientMetadata
    }

    return CurrentPlaybackItem(
      sourceItemID: normalizedID,
      title: normalizedTitle,
      artistName: normalized(artistName),
      albumTitle: normalized(albumTitle),
      kind: kind
    )
  }

  private func normalized(_ value: String?) -> String? {
    guard let value else { return nil }
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalized.isEmpty ? nil : normalized
  }
}
