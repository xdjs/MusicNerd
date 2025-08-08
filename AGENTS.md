# Repository Guidelines

## Project Structure & Module Organization
- `TrackNerd/`: App source (SwiftUI). Key folders: `Views/`, `Models/`, `Services/`, `Assets.xcassets/`.
- `TrackNerdTests/`: Unit tests (XCTest).
- `TrackNerdUITests/`: UI tests (XCUITest).
- `TrackNerd.xcodeproj/`: Xcode project.
- `fastlane/`: Automation (`Fastfile`, reports in `testResults/`).

## Build, Test, and Development Commands
- Build (Xcode): `open TrackNerd.xcodeproj` then run the `TrackNerd` scheme.
- Build (CLI): `xcodebuild -project TrackNerd.xcodeproj -scheme TrackNerd -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' build`.
- Unit tests: `fastlane ios test` (runs `TrackNerdTests`).
- UI tests: `fastlane ios ui_test` (runs `TrackNerdUITests`).
- All tests: `fastlane ios test_all`. Clean: `fastlane ios clean`.

## Coding Style & Naming Conventions
- Language: Swift (2‑space indentation, no tabs).
- Types: `PascalCase` (e.g., `SongMatch`); methods/properties: `camelCase`.
- Files: one primary type per file; filename matches type (e.g., `MusicNerdService.swift`).
- Structure: UI in `Views/`, models in `Models/`, services in `Services/`.
- Use SwiftUI and MVVM patterns; prefer value types and `struct` for models.

## Testing Guidelines
- Frameworks: XCTest (unit), XCUITest (UI).
- Simulator target: iPhone SE (3rd generation), iOS 18.2 (matches Fastlane).
- Naming: test files end with `Tests.swift`; test methods start with `test...`.
- UI tests should add `--uitesting` launch arg; animations are disabled in this mode.
- Artifacts: result bundles written to `testResults/` by Fastlane lanes.

## Commit & Pull Request Guidelines
- Commits: concise, present‑tense, imperative (e.g., “Add…” "Fix…"). Group related changes.
- Branching: create feature branches; avoid direct pushes to `main`.
- PRs: include summary, rationale, screenshots for UI changes, and steps to test. Link issues.
- Verification: run `fastlane ios test_all` locally and ensure `testResults/` is clean of failures.

## Security & Configuration Tips
- Server selection lives in app Settings > Debug (Production vs. Development). Do not hardcode secrets.
- Requires microphone permission for ShazamKit; handle denial paths in changes touching recognition.
