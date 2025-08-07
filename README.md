# TrackNerd

iOS app that identifies music using ShazamKit and provides AI-powered insights through the MusicNerd service.

## Features

- Real-time music recognition via ShazamKit
- AI-generated artist insights and fun facts
- Local storage of recognized songs
- Match history with detailed views
- Configurable sample duration and cache settings

## Requirements

- iOS 18.2+
- Xcode 16+
- Microphone permissions
- Network access

## Setup

1. Open `TrackNerd.xcodeproj` in Xcode
2. Build and run on iOS Simulator or device
3. Grant microphone permissions when prompted

## Configuration

The app connects to the MusicNerd service for AI insights. You can switch between production and development servers in Settings > Debug > Use Production Server.

- Production: `api.musicnerd.xyz`
- Development: `localhost:3000`

## Testing

Run unit tests:
```bash
fastlane ios test
```

Run all tests (unit + UI):
```bash
fastlane ios test_all
```

Manual test commands are available in `CLAUDE.md`.

## Architecture

- **SwiftUI** - UI framework
- **MVVM** - Architecture pattern
- **ShazamKit** - Music recognition
- **Core Data** - Local storage
- **URLSession** - Network requests

Key directories:
- `Views/` - SwiftUI components
- `ViewModels/` - MVVM view models  
- `Services/` - Business logic
- `Models/` - Data models

## Development

See `CLAUDE.md` for detailed development guidelines, build commands, and testing procedures.