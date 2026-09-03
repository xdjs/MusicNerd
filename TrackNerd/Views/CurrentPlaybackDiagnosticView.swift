#if DEBUG
import SwiftUI

struct CurrentPlaybackDiagnosticView: View {
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var viewModel = CurrentPlaybackDiagnosticViewModel()

  var body: some View {
    List {
      authorizationSection
      captureSection

      if let errorMessage = viewModel.errorMessage {
        Section {
          Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
            .foregroundColor(Color.MusicNerd.error)
            .accessibilityIdentifier("current-playback-error")
        }
      }

      if let report = viewModel.report {
        resultSection(report)
        comparisonSection(report.comparison)
        snapshotSection(title: "Before Read", snapshot: report.before)
        snapshotSection(title: "After Read", snapshot: report.after)
      }
    }
    .listStyle(InsetGroupedListStyle())
    .background(Color.MusicNerd.background)
    .navigationTitle("Current Playback")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.refreshAuthorizationStatus()
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        viewModel.refreshAuthorizationStatus()
      }
    }
  }

  private var authorizationSection: some View {
    Section {
      HStack(spacing: CGFloat.MusicNerd.md) {
        Image(systemName: authorizationIcon)
          .foregroundColor(authorizationColor)
          .frame(width: 24)

        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.xs) {
          Text("Apple Music Access")
            .musicNerdStyle(.bodyLarge())
          Text(authorizationDescription)
            .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
        }
      }

      switch viewModel.authorizationStatus {
      case .notDetermined:
        MusicNerdButton(
          title: "Allow Apple Music Access",
          action: {
            Task { await viewModel.requestAuthorization() }
          },
          isLoading: viewModel.isRequestingAuthorization,
          icon: "music.note"
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("current-playback-request-authorization")
      case .denied:
        MusicNerdButton(
          title: "Open Settings",
          action: openSettings,
          style: .outline,
          icon: "gear"
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("current-playback-open-settings")
      case .restricted, .authorized, .unknown:
        EmptyView()
      }
    } header: {
      Text("Authorization")
        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
    }
  }

  private var captureSection: some View {
    Section {
      VStack(alignment: .leading, spacing: CGFloat.MusicNerd.md) {
        Text(
          "This debug diagnostic reads the system queue through a separate resolver. " +
          "Its interface exposes no play, pause, seek, skip, restart, or queue replacement commands."
        )
        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))

        MusicNerdButton(
          title: "Capture Before/After",
          action: {
            Task { await viewModel.capture() }
          },
          isEnabled: viewModel.canCapture,
          isLoading: viewModel.isCapturing,
          icon: "waveform.path.ecg"
        )
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("current-playback-capture")
      }
    } header: {
      Text("Read-only Diagnostic")
        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
    } footer: {
      Text("Results remain on this screen only. No backend, persistence, or analytics are used.")
    }
  }

  private func resultSection(_ report: PlaybackDiagnosticReport) -> some View {
    Section {
      switch report.resolution {
      case .resolved(let item):
        diagnosticValueRow(label: "Kind", value: item.kind.displayName)
        diagnosticValueRow(label: "MusicKit source ID", value: item.sourceItemID)
        diagnosticValueRow(label: "Title", value: item.title)
        diagnosticValueRow(label: "Artist", value: item.artistName ?? "Unavailable")
        diagnosticValueRow(label: "Album", value: item.albumTitle ?? "Unavailable")
      case .failed(let error):
        Label(error.localizedDescription, systemImage: "questionmark.circle")
          .foregroundColor(Color.MusicNerd.warning)
      case .unexpectedFailure(let message):
        Label(message, systemImage: "exclamationmark.triangle.fill")
          .foregroundColor(Color.MusicNerd.error)
      }
    } header: {
      Text("Resolution")
        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
    }
    .accessibilityIdentifier("current-playback-result")
  }

  private func comparisonSection(_ comparison: PlaybackComparisonResult) -> some View {
    Section {
      switch comparison {
      case .noUnexpectedChange:
        Label {
          VStack(alignment: .leading, spacing: CGFloat.MusicNerd.xs) {
            Text("No unexpected playback change")
              .musicNerdStyle(.bodyLarge())
            Text("Queue identity, item identity, transient state, transport state, and position stayed within tolerance.")
              .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
          }
        } icon: {
          Image(systemName: "checkmark.shield.fill")
            .foregroundColor(Color.MusicNerd.success)
        }
      case .possibleMutation(let differences):
        Label {
          VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
            Text("Possible playback change")
              .musicNerdStyle(.bodyLarge())
            ForEach(Array(differences.enumerated()), id: \.offset) { _, difference in
              Text("• \(difference.description)")
                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
            }
          }
        } icon: {
          Image(systemName: "exclamationmark.shield.fill")
            .foregroundColor(Color.MusicNerd.error)
        }
      case .inconclusive(let reason):
        Label {
          VStack(alignment: .leading, spacing: CGFloat.MusicNerd.xs) {
            Text("Inconclusive — repeat capture")
              .musicNerdStyle(.bodyLarge())
            Text(reason)
              .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
          }
        } icon: {
          Image(systemName: "arrow.clockwise.circle.fill")
            .foregroundColor(Color.MusicNerd.warning)
        }
      }
    } header: {
      Text("Mutation Safety")
        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
    }
  }

  private func snapshotSection(
    title: String,
    snapshot: PlaybackDiagnosticSnapshot
  ) -> some View {
    Section {
      diagnosticValueRow(
        label: "Captured",
        value: snapshot.capturedAt.formatted(date: .omitted, time: .standard)
      )
      diagnosticValueRow(label: "Queue entry ID", value: snapshot.queueEntryID ?? "None")
      diagnosticValueRow(label: "Entry title", value: snapshot.entryTitle ?? "None")
      diagnosticValueRow(label: "Entry subtitle", value: snapshot.entrySubtitle ?? "None")
      diagnosticValueRow(label: "Transient", value: snapshot.isTransient ? "Yes" : "No")
      diagnosticValueRow(label: "Transient item ID", value: snapshot.transientItemID ?? "None")
      diagnosticValueRow(label: "Transient item type", value: snapshot.transientItemType ?? "None")
      diagnosticValueRow(label: "Playback status", value: snapshot.playbackStatus.displayName)
      diagnosticValueRow(
        label: "Playback position",
        value: String(format: "%.3f seconds", snapshot.playbackTime)
      )
    } header: {
      Text(title)
        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
    }
  }

  private func diagnosticValueRow(label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: CGFloat.MusicNerd.xs) {
      Text(label)
        .musicNerdStyle(.captionBold(color: Color.MusicNerd.textSecondary))
      Text(value)
        .font(Font.MusicNerd.monoSmall)
        .foregroundColor(Color.MusicNerd.text)
        .textSelection(.enabled)
    }
  }

  private var authorizationIcon: String {
    switch viewModel.authorizationStatus {
    case .authorized:
      return "checkmark.circle.fill"
    case .notDetermined:
      return "questionmark.circle.fill"
    case .denied, .restricted:
      return "xmark.circle.fill"
    case .unknown:
      return "exclamationmark.circle.fill"
    }
  }

  private var authorizationColor: Color {
    switch viewModel.authorizationStatus {
    case .authorized:
      return Color.MusicNerd.success
    case .notDetermined, .unknown:
      return Color.MusicNerd.warning
    case .denied, .restricted:
      return Color.MusicNerd.error
    }
  }

  private var authorizationDescription: String {
    switch viewModel.authorizationStatus {
    case .authorized:
      return "Authorized. The diagnostic can read the current system queue entry."
    case .notDetermined:
      return "Not requested. Grant access before reading Apple Music playback."
    case .denied:
      return "Denied. Enable Media & Apple Music access in Settings."
    case .restricted:
      return "Restricted by device policy or parental controls."
    case .unknown:
      return "The system returned an authorization state this build does not recognize."
    }
  }

  private func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }
}

#Preview {
  NavigationView {
    CurrentPlaybackDiagnosticView()
  }
}
#endif
