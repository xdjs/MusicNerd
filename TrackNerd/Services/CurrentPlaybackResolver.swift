import Foundation
import MusicKit

@MainActor
protocol CurrentPlaybackResolving: Sendable {
  func currentItem() async throws -> CurrentPlaybackItem
}

@MainActor
struct MusicKitCurrentPlaybackResolver: CurrentPlaybackResolving {
  private let authorizationProvider: any MusicAuthorizationProviding
  private let sourceReader: any CurrentPlaybackSourceReading
  private let mapper: CurrentPlaybackItemMapper

  init(
    authorizationProvider: (any MusicAuthorizationProviding)? = nil,
    sourceReader: (any CurrentPlaybackSourceReading)? = nil,
    mapper: CurrentPlaybackItemMapper = CurrentPlaybackItemMapper()
  ) {
    self.authorizationProvider = authorizationProvider ?? MusicKitAuthorizationProvider()
    self.sourceReader = sourceReader ?? MusicKitCurrentPlaybackSourceReader()
    self.mapper = mapper
  }

  func currentItem() async throws -> CurrentPlaybackItem {
    let authorizationStatus = authorizationProvider.currentStatus
    guard authorizationStatus == .authorized else {
      throw CurrentPlaybackError.authorizationRequired(authorizationStatus)
    }

    guard let sourceItem = sourceReader.currentSourceItem() else {
      throw CurrentPlaybackError.nothingPlaying
    }

    return try mapper.map(sourceItem)
  }

  static func item(from entry: MusicPlayer.Queue.Entry) throws -> CurrentPlaybackItem {
    try CurrentPlaybackItemMapper().map(
      MusicKitCurrentPlaybackSourceReader.sourceItem(from: entry)
    )
  }
}
