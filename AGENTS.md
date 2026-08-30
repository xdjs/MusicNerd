# Repository Guidelines

## Project Overview

Music Nerd is a SwiftUI app for iOS 18.2 and later. It identifies nearby music with ShazamKit, stores discoveries locally with SwiftData, enriches artists through the Music Nerd service, and supports Apple Music or preview playback.

The iOS client does not call OpenAI directly. `OpenAIService` is the existing enrichment orchestrator over `MusicNerdService`, which talks to the Music Nerd backend.

## Project Structure

- `TrackNerd/`: App source. The directory retains its legacy name; the app target and product are named `MusicNerd`. Do not rename legacy directories as part of unrelated work.
  - `Views/`: SwiftUI screens, reusable components, and the design system.
  - `ViewModels/`: Screen-level view models.
  - `Models/`: SwiftData models, API payloads, settings, and errors.
  - `Services/`: Recognition, enrichment, persistence, reachability, permissions, and playback.
  - `Assets.xcassets/`: App icons and colors.
- `TrackNerdTests/`: Unit tests for the `MusicNerdTests` target.
- `TrackNerdUITests/`: UI tests for the `MusicNerdUITests` target.
- `MusicNerd.xcodeproj/`: Xcode project and shared `MusicNerd` scheme.
- `plans/`: Product roadmap and Xcode test plans.
- `fastlane/`: Local build and test automation. Result bundles are written under `testResults/`.

## Architecture and Data Flow

- Use SwiftUI for UI and follow the existing MVVM/service-container boundaries. Put reusable business logic in view models or services rather than expanding view bodies.
- `ShazamService` streams microphone buffers to ShazamKit and produces a `SongMatch`.
- `StorageService` and `EnrichmentCache` persist matches and enrichment data with SwiftData.
- `MusicNerdService` searches the Music Nerd backend and retrieves artist biographies and categorized facts.
- `AppleMusicService` handles MusicKit authorization, catalog lookup, preview playback, and subscriber playback.
- `AppSettings` stores nonsecret preferences in `UserDefaults`.
- Use the protocols in `TrackNerd/Services/Container.swift` for dependency injection and test doubles.
- Keep UI work on the main actor. Do not pass SwiftData persistent models across actor boundaries; pass stable identifiers or fetch them in the owning model context.

## Build and Development Commands

Use Xcode 16 or later. Run Fastlane through Bundler so commands use the version pinned in `Gemfile`.

Open the project in Xcode:

```bash
open MusicNerd.xcodeproj
```

Build from the command line:

```bash
xcodebuild \
  -project MusicNerd.xcodeproj \
  -scheme MusicNerd \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' \
  build
```

Fastlane lanes:

```bash
bundle exec fastlane ios build       # Build the app for testing
bundle exec fastlane ios test        # Run UnitTestPlan
bundle exec fastlane ios ui_test     # Run UITestPlan
bundle exec fastlane ios dev_test    # Run DevTestPlan
bundle exec fastlane ios test_all    # Run unit and UI test plans
bundle exec fastlane ios ci          # Build and run unit tests
bundle exec fastlane ios clean       # Clear derived data and test results
bundle exec fastlane lanes           # List available lanes
```

Fastlane expects an iPhone SE (3rd generation) simulator running iOS 18.2. If needed, prepare it with:

```bash
xcrun simctl boot 'iPhone SE (3rd generation)'
xcrun simctl spawn booted launchctl setenv SIMULATOR_SLOW_MOTION_TIMEOUT 0
```

Do not automatically run the full UI test suite. Run it when the user requests it, when validating UI behavior, or before a release/PR where end-to-end verification is appropriate. Prefer focused unit or UI tests while iterating.

## Coding Style

- Use Swift with 2-space indentation and no tabs.
- Name types in `PascalCase`; name methods and properties in `camelCase`.
- Keep one primary type per file and match the filename to that type.
- Place UI, models, view models, and services in their corresponding directories.
- Prefer value types for ordinary data. SwiftData persistence models must remain `@Model` reference types.
- Reuse the design-system colors, spacing, typography, cards, buttons, and loading states for UI changes.
- Preserve user-friendly permission, offline, cancellation, and retry states when changing recognition or networking.
- Coordinate audio capture and playback carefully. Stop playback before microphone capture and release/deactivate capture resources on every terminal path.
- Do not introduce hardcoded secrets, API keys, or credentials.

## Testing Guidelines

- Unit tests use XCTest and Swift Testing; UI tests use XCUITest.
- Test files end in `Tests.swift`; XCTest methods start with `test`.
- UI test setup must pass the `--uitesting` launch argument. The app disables UIKit animations when this argument is present.
- Keep unit tests deterministic. Mock network and system-service boundaries; unit tests must not call production Music Nerd endpoints.
- Add or update focused tests for behavior changes, especially persistence, filtering, recognition state transitions, enrichment fallbacks, and playback state.
- Real microphone, Shazam catalog, MusicKit subscription, and device audio-session behavior require appropriate device/manual coverage in addition to mocks.
- Fastlane result bundles belong in `testResults/`; do not commit generated test artifacts.

## Configuration, Privacy, and Security

- Runtime server selection is in Settings > Debug: production uses `https://api.musicnerd.xyz`; development uses `http://localhost:3000`.
- Recognition requires microphone permission and network access. Changes to recognition must preserve denial and restricted-permission paths.
- Apple Music playback requires its usage description, authorization handling, and the appropriate signing capability.
- The app should not persist raw microphone audio. Treat recognized-song history, artist identifiers, API responses, and console output as user data.
- Avoid logging full response bodies or sensitive headers in production code. Respect the existing log-suppression setting when extending Music Nerd API logging.
- Do not add analytics or new external data sharing without explicit product direction and the required privacy disclosures.

## Plans, Git, and Pull Requests

- Use `plans/MusicNerdMVP.md` for roadmap context, but verify claims against the current implementation before relying on phase status.
- Before a requested commit, update a relevant project plan when the change completes or materially changes a planned task.
- Do not commit, push, or create a pull request unless explicitly instructed.
- Use concise, present-tense, imperative commit messages and group related changes.
- Work on feature branches and avoid direct pushes to `main`.
- Pull requests should include a summary, rationale, test evidence, linked issues, and screenshots for visible UI changes.
- Before release or a broad PR, run the relevant unit and UI plans and confirm `testResults/` contains no failures.
