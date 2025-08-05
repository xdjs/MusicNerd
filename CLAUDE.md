# TrackNerd - Music Nerd + Shazam iOS App

## Project Overview
TrackNerd is an iOS app that combines ShazamKit music recognition with OpenAI-powered insights to create a "Music Nerd" experience. The app identifies songs and provides deep, playful insights about tracks and artists.

## Architecture
- **Language**: Swift
- **Framework**: SwiftUI
- **Platform**: iOS 17.0+
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
open TrackNerd.xcodeproj

# Build from command line
xcodebuild -project TrackNerd.xcodeproj -scheme TrackNerd -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' build
```

### Testing

#### Test Setup (Required before all tests)
```bash
xcrun simctl boot "iPhone SE (3rd generation)"
xcrun simctl spawn booted launchctl setenv SIMULATOR_SLOW_MOTION_TIMEOUT 0
```

#### Run Unit Tests
```bash
xcodebuild test \
  -project TrackNerd.xcodeproj \
  -scheme TrackNerd \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' \
  -only-testing:TrackNerdTests \
  -quiet \
  -resultBundlePath "testResults/$(date +%Y%m%d_%H%M%S)/UnitTests.xcresult"
```

#### Run UI Tests
```bash
xcodebuild test \
  -project TrackNerd.xcodeproj \
  -scheme TrackNerd \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.2' \
  -only-testing:TrackNerdUITests \
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
- App disables animations during UI testing with conditional in `TrackNerdApp.swift`:
  ```swift
  if ProcessInfo.processInfo.arguments.contains("--uitesting") {
      UIView.setAnimationsEnabled(false)
  }
  ```

### Testing Structure
- Unit tests: `TrackNerdTests/`
- UI tests: `TrackNerdUITests/`

## Development Status
Currently in Phase 1 (Project Setup) - basic SwiftUI project with branding assets configured. Next phase involves implementing ShazamKit integration for music recognition.

## Key Files
- `TrackNerdApp.swift` - Main app entry point
- `ContentView.swift` - Primary view (currently placeholder)
- `plans/TrackNerdMVP.md` - Detailed project roadmap and phase breakdown

## Requirements
- iOS 17.0+
- Microphone permissions (for ShazamKit)
- Network access (for OpenAI enrichment)
- ShazamKit framework
- Planned: OpenAI API integration via proxy server
