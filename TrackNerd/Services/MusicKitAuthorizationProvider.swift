import MusicKit

@MainActor
protocol MusicAuthorizationProviding: Sendable {
  var currentStatus: PlaybackAuthorizationStatus { get }
  func requestAuthorization() async -> PlaybackAuthorizationStatus
}

@MainActor
struct MusicKitAuthorizationProvider: MusicAuthorizationProviding {
  var currentStatus: PlaybackAuthorizationStatus {
    Self.map(MusicAuthorization.currentStatus)
  }

  func requestAuthorization() async -> PlaybackAuthorizationStatus {
    Self.map(await MusicAuthorization.request())
  }

  private static func map(_ status: MusicAuthorization.Status) -> PlaybackAuthorizationStatus {
    switch status {
    case .notDetermined:
      return .notDetermined
    case .denied:
      return .denied
    case .restricted:
      return .restricted
    case .authorized:
      return .authorized
    @unknown default:
      return .unknown
    }
  }
}
