import AppIntents

struct MusicNerdAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ExplainCurrentArtistIntent(),
      phrases: [
        "Explain the current artist with \(.applicationName)",
        "Describe the artist playing with \(.applicationName)",
        "Get current artist details from \(.applicationName)",
        "Start an artist briefing with \(.applicationName)"
      ],
      shortTitle: "About This Artist",
      systemImageName: "person.wave.2"
    )
  }

  static var shortcutTileColor: ShortcutTileColor { .purple }
}
