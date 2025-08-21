# MusicNerd - Music Nerd + Shazam iOS App

## Project Overview
MusicNerd is an iOS app that combines ShazamKit music recognition with OpenAI-powered insights to create a "Music Nerd" experience. The app identifies songs and provides deep, playful insights about tracks and artists.

## Architecture
- **Language**: Swift
- **Framework**: SwiftUI
- **Platform**: iOS 18.2+
- **Project Structure**:
  - `/Views` - SwiftUI view components
  - `/ViewModels` - MVVM view models
  - `/Services` - Business logic and API services
  - `/Models` - Data models

## Key Features (Planned)
- Real-time music recognition using ShazamKit
- AI-powered song and artist insights via OpenAI
- Local storage of recognized songs
- Match history with detailed view
- Music Nerd branding with pink theme

## Development Commands

### Build & Run
```bash
# Open project in Xcode
open MusicNerd.xcodeproj

# Build from command line
xcodebuild -project MusicNerd.xcodeproj -scheme MusicNerd -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' build
```

### Fastlane Automation

Fastlane is configured for streamlined build and testing. Available lanes:

#### Build
```bash
# Build the app for testing
fastlane ios build
```

#### Testing
```bash
# Run unit tests only
fastlane ios test

# Run UI tests only
fastlane ios ui_test

# Run all tests (unit and UI)
fastlane ios test_all

# Run dev test plan
faastlane ios dev_test

# Build and run unit tests (CI pipeline)
fastlane ios ci
```

#### Maintenance
```bash
# Clean derived data and test results
fastlane ios clean

# List all available lanes
fastlane lanes
```

### Manual Testing

#### Test Setup (Required before all tests)
```bash
xcrun simctl boot "iPhone SE (3rd generation)"
xcrun simctl spawn booted launchctl setenv SIMULATOR_SLOW_MOTION_TIMEOUT 0
```

#### Run Unit Tests
```bash
xcodebuild test \
  -project MusicNerd.xcodeproj \
  -scheme MusicNerd \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' \
  -only-testing:MusicNerdTests \
  -quiet \
  -resultBundlePath "testResults/$(date +%Y%m%d_%H%M%S)/UnitTests.xcresult"
```

#### Run UI Tests
```bash
xcodebuild test \
  -project MusicNerd.xcodeproj \
  -scheme MusicNerd \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' \
  -only-testing:MusicNerdUITests \
  -quiet \
  -resultBundlePath "testResults/$(date +%Y%m%d_%H%M%S)/UITests.xcresult"
```

#### Test Configuration
- **Base iOS Version**: 18.2
- **Test Device**: iPhone SE (3rd generation) for ALL tests
- **Test Execution**: Run all unit tests headlessly
- **Phase Completion**: A phase is not completed until all unit tests and UI tests have been written, run, and passed

#### UI Testing Setup
- UI tests include `app.launchArguments.append("--uitesting")` in setup
- App disables animations during UI testing with conditional in `MusicNerdApp.swift`:
  ```swift
  if ProcessInfo.processInfo.arguments.contains("--uitesting") {
      UIView.setAnimationsEnabled(false)
  }
  ```

### Testing Structure
- Unit tests: `MusicNerdTests/`
- UI tests: `MusicNerdUITests/`

## Development Status
Currently beginning Phase 3 (Music Recognition Core) - Phases 1 (Foundation & Architecture) and 2 (UI/UX Foundation) are complete. Current phase involves implementing ShazamKit integration for real-time music recognition.

## Key Files
- `MusicNerdApp.swift` - Main app entry point
- `ContentView.swift` - Primary view (currently placeholder)
- `plans/MusicNerdMVP.md` - Detailed project roadmap and phase breakdown

## Requirements
- iOS 18.2+
- Microphone permissions (for ShazamKit)
- Network access (for OpenAI enrichment)
- ShazamKit framework
- Planned: OpenAI API integration via proxy server

## Development Memories
- Do not automatically run UI tests
- Before committing files, update the project plan, if there is one, and if necessary mark any tasks completed.
- Do not commit unless instructed to
