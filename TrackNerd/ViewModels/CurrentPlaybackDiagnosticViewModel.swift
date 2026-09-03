#if DEBUG
import Combine
import Foundation

@MainActor
final class CurrentPlaybackDiagnosticViewModel: ObservableObject {
  @Published private(set) var authorizationStatus: PlaybackAuthorizationStatus
  @Published private(set) var report: PlaybackDiagnosticReport?
  @Published private(set) var errorMessage: String?
  @Published private(set) var isRequestingAuthorization = false
  @Published private(set) var isCapturing = false

  private let authorizationProvider: any MusicAuthorizationProviding
  private let diagnosticRunner: any PlaybackDiagnosticRunning

  init(
    authorizationProvider: (any MusicAuthorizationProviding)? = nil,
    diagnosticRunner: (any PlaybackDiagnosticRunning)? = nil
  ) {
    let authorizationProvider = authorizationProvider ?? MusicKitAuthorizationProvider()
    self.authorizationProvider = authorizationProvider
    self.diagnosticRunner = diagnosticRunner ?? MusicKitPlaybackDiagnosticRunner(
      authorizationProvider: authorizationProvider
    )
    authorizationStatus = authorizationProvider.currentStatus
  }

  var canCapture: Bool {
    authorizationStatus == .authorized && !isRequestingAuthorization && !isCapturing
  }

  func refreshAuthorizationStatus() {
    authorizationStatus = authorizationProvider.currentStatus
  }

  func requestAuthorization() async {
    guard !isRequestingAuthorization else { return }

    isRequestingAuthorization = true
    errorMessage = nil
    authorizationStatus = await authorizationProvider.requestAuthorization()
    isRequestingAuthorization = false

    if authorizationStatus != .authorized {
      errorMessage = CurrentPlaybackError
        .authorizationRequired(authorizationStatus)
        .localizedDescription
    }
  }

  func capture() async {
    guard canCapture else { return }

    isCapturing = true
    errorMessage = nil
    report = nil
    defer { isCapturing = false }

    do {
      report = try await diagnosticRunner.capture()
    } catch let error as CurrentPlaybackError {
      authorizationStatus = authorizationProvider.currentStatus
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = "The playback diagnostic failed: \(error.localizedDescription)"
    }
  }
}
#endif
