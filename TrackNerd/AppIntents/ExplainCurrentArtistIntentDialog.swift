import Foundation

enum ExplainCurrentArtistIntentDialog {
  static func message(for error: any Error) -> String {
    if error is CancellationError {
      return "Okay, I stopped."
    }

    if let playbackError = error as? CurrentPlaybackError {
      return message(for: playbackError)
    }

    if let identityError = error as? MusicIdentityError {
      return message(for: identityError)
    }

    if let knowledgeError = error as? MusicKnowledgeError {
      return message(for: knowledgeError)
    }

    return "Music Nerd couldn't answer right now. Try again."
  }

  private static func message(for error: CurrentPlaybackError) -> String {
    switch error {
    case .authorizationRequired(let status):
      switch status {
      case .notDetermined:
        return "Open Music Nerd and allow Apple Music access first."
      case .denied:
        return "Allow Apple Music access for Music Nerd in Settings."
      case .restricted:
        return "Apple Music access is restricted on this device."
      case .authorized:
        return "Apple Music access changed. Try again."
      case .unknown:
        return "Apple Music access is unavailable right now."
      }
    case .nothingPlaying:
      return "Play something in Apple Music, then try again."
    case .itemUnavailable:
      return "I can't read the current Apple Music item. Try another song."
    case .unsupportedItem:
      return "That type of Apple Music item isn't supported yet."
    case .insufficientMetadata:
      return "The current item doesn't have enough artist information."
    }
  }

  private static func message(for error: MusicIdentityError) -> String {
    switch error {
    case .missingArtistMetadata:
      return "The current item doesn't have enough artist information."
    case .noMatch, .belowConfidenceThreshold:
      return "Music Nerd doesn't have a confident match for this artist."
    case .ambiguousMatch:
      return "Music Nerd found multiple possible artists and won't guess."
    case .offline:
      return "Music Nerd is offline. Reconnect and try again."
    case .timedOut:
      return "Music Nerd took too long to identify the artist. Try again."
    case .serviceUnavailable:
      return "Music Nerd's artist service is unavailable right now."
    }
  }

  private static func message(for error: MusicKnowledgeError) -> String {
    switch error {
    case .missingArtistIdentity, .lowConfidence:
      return "Music Nerd doesn't have a confident match for this artist."
    case .songKnowledgeUnavailable:
      return "Music Nerd can't explain this artist yet."
    case .noData:
      return "Music Nerd doesn't have artist details yet."
    case .offline:
      return "Music Nerd is offline. Reconnect and try again."
    case .timedOut:
      return "Music Nerd took too long to answer. Try again."
    case .serviceUnavailable:
      return "Music Nerd's artist service is unavailable right now."
    }
  }
}
