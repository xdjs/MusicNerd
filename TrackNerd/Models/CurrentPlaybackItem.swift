import Foundation

enum PlaybackAuthorizationStatus: String, Equatable, Sendable {
  case notDetermined
  case denied
  case restricted
  case authorized
  case unknown
}

enum CurrentPlaybackError: LocalizedError, Equatable, Sendable {
  case authorizationRequired(PlaybackAuthorizationStatus)
  case nothingPlaying
  case itemUnavailable
  case unsupportedItem
  case insufficientMetadata

  var errorDescription: String? {
    switch self {
    case .authorizationRequired(let status):
      switch status {
      case .notDetermined:
        return "Apple Music access has not been requested."
      case .denied:
        return "Apple Music access was denied. Enable it in Settings to continue."
      case .restricted:
        return "Apple Music access is restricted on this device."
      case .authorized:
        return "Apple Music access changed while the request was running."
      case .unknown:
        return "Apple Music access is unavailable in an unknown state."
      }
    case .nothingPlaying:
      return "The system Apple Music queue has no current entry."
    case .itemUnavailable:
      return "The current queue entry does not expose a typed MusicKit item."
    case .unsupportedItem:
      return "The current queue entry contains an unsupported MusicKit item."
    case .insufficientMetadata:
      return "The current MusicKit item does not contain enough metadata to identify it."
    }
  }
}

struct CurrentPlaybackItem: Equatable, Sendable {
  enum Kind: String, Equatable, Sendable {
    case song
    case musicVideo

    var displayName: String {
      switch self {
      case .song:
        return "Song"
      case .musicVideo:
        return "Music Video"
      }
    }
  }

  let sourceItemID: String
  let title: String
  let artistName: String?
  let albumTitle: String?
  let kind: Kind

  var stableIdentity: String {
    "\(kind.rawValue):\(sourceItemID)"
  }
}

enum CurrentPlaybackSourceItem: Equatable, Sendable {
  case song(
    sourceItemID: String,
    title: String,
    artistName: String?,
    albumTitle: String?
  )
  case musicVideo(
    sourceItemID: String,
    title: String,
    artistName: String?,
    albumTitle: String?
  )
  case unavailable
  case unsupported
}
