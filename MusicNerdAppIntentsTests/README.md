# Music Nerd App Intents integration tests

This iOS 27 UI-testing bundle validates Music Nerd's App Intents out of process
through `AppIntentsTesting`. It is intentionally separate from
`MusicNerdUITests`, `UITestPlan.xctestplan`, and the existing Fastlane lanes.

Run it with the shared `MusicNerdAppIntentsTests` scheme on an iOS 27 simulator:

```bash
xcodebuild \
  -project MusicNerd.xcodeproj \
  -scheme MusicNerdAppIntentsTests \
  -testPlan AppIntentsTestPlan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0' \
  test
```

The tests launch the app with `--uitesting`, reset shared debug scenario state
before and after each test, and run serially. Debug-only setup/reset intents seed
deterministic success and failure cases without relying on a MusicKit queue or a
production Music Nerd endpoint.
