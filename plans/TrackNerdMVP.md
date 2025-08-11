# 🎧 Music Nerd + Shazam MVP — Project Plan

## ✅ Overview

Build an iOS app under the Music Nerd brand that:
- Uses **ShazamKit** to identify music
- Uses **OpenAI** (via proxy) to generate deep-but-playful song and artist insights
- Stores recognized songs locally
- Has clean SwiftUI UI with Music Nerd branding
- Preps for TestFlight and eventual App Store release

---

## 📆 Phases and Tasks

### 🧱 Phase 1: Foundation & Architecture ✅
- [x] Create new SwiftUI Xcode project
- [x] Set iOS Deployment Target to 17.0+
- [x] Set bundle identifier
- [x] Add Music Nerd assets (pink background, glasses logo)
- [x] Set up folder structure (`/Views`, `/ViewModels`, `/Services`, `/Models`)
- [x] Define core data models:
  - [x] `SongMatch` model (title, artist, artwork, enrichment data)
  - [x] `EnrichmentData` model (bio, trivia, related content)
  - [x] Error types and result enums
- [x] Set up dependency injection container
- [x] Configure app-wide constants and configuration
- [x] **Unit Testing:**
  - [x] Test data model validation and encoding/decoding
  - [x] Test dependency injection setup
  - [x] Test configuration parsing and constants
- [x] **UI Testing:**
  - [x] Test app launch and initial state
  - [x] Verify basic navigation structure

---

### 🎨 Phase 2: UI/UX Foundation ✅
- [x] **Design system setup:**
  - [x] Music Nerd color palette and typography
  - [x] Custom UI components (buttons, cards, loading states)
  - [x] Consistent spacing and styling
- [x] **Core navigation structure:**
  - [x] Main listening view (ListeningView with TabView)
  - [x] History/library view (HistoryView with search and empty states)
  - [x] Settings view (SettingsView with toggles and preferences)
- [x] **Base view components with proper accessibility:**
  - [x] TabView navigation with accessibility identifiers
  - [x] Listening interface with "What's Playing?" UI
  - [x] History with search functionality and match cards
  - [x] Settings with toggle controls and sections
- [x] **Unit Testing:**
  - [x] Test custom UI component logic and state
  - [x] Test view model initialization and data binding
  - [x] Test navigation routing logic
  - [x] Fixed AppConfiguration API URL test
- [x] **UI Testing:**
  - [x] Test tab navigation between main sections
  - [x] Verify accessibility identifiers on all components
  - [x] Test responsive layout on different device sizes
  - [x] Fixed all DesignSystemUITests for new navigation structure
  - [x] All 27 UI tests now passing

---

### 🎙 Phase 3: Music Recognition Core ✅
- [x] **Permissions & Setup**:
  - [x] Request microphone permission with proper messaging
  - [x] Add Info.plist descriptions for privacy
- [x] **ShazamKit Integration**:
  - [x] `ShazamService` with real `SHSignatureGenerator` and audio capture
  - [x] `SHSession` for catalog matching with full delegate implementation
  - [x] Parse metadata (title, artist, albumArtURL, AppleMusicID, shazamID)
  - [x] Handle recognition states (listening, processing, success, failure)
  - [x] Audio engine tap lifecycle management (prevents crashes)
  - [x] Enhanced error handling for signature validation
- [x] **Recognition UI**:
  - [x] Listening animation (waveform/pulse)
  - [x] Recognition results display
  - [x] Real-time state updates during recognition flow
  - [x] Display album cover art when match is found
  - [x] Show placeholder cover art during listening/recognition
  - [ ] Enhanced audio visualization during capture (deferred to future release)
- [x] **Settings & Configuration**:
  - [x] Configurable sample duration (3, 5, 10, 15, 20 seconds)
  - [x] Sample duration picker UI in Settings
  - [x] UserDefaults-based settings persistence
  - [x] User-friendly duration descriptions and recommendations
  - [x] Debug toggle to display sample duration in main UI
- [x] **Production Readiness**:
  - [x] Professional debug logging with timestamps
  - [x] Comprehensive error handling and user-friendly messages
  - [x] Audio capture validation and feedback
  - [x] Multiple recognition session support without crashes
- [x] **Unit Testing:**
  - [x] Test ShazamService state management
  - [x] Test metadata parsing structure
  - [x] Test permission handling logic
  - [x] Safe test skipping for system dialog tests
  - [x] Mock services for deterministic testing
- [x] **UI Testing:**
  - [x] Test microphone permission flow
  - [x] Test recognition button interactions
  - [x] Test listening state animations
  - [x] Test recognition success/failure UI states
  - [x] Test results display with sample data

**Phase 3 Production Enhancements:**
- [x] Replace mock ShazamKit implementation with real audio capture
- [x] Test real ShazamKit audio signature generation and recognition
- [x] Add comprehensive debug logging and error handling
- [x] Implement configurable sample duration with settings UI
- [x] Fix AVAudioEngine tap lifecycle issues
- [x] Add ShazamKit signature validation and user-friendly error messages

---

### 🔌 Phase 4: Backend Services & Integration ✅
- [x] **Leverage MusicNerdNG OpenAI APIs**:
  - [x] Configure app to point to development vs production MusicNerd server endpoints
  - [x] Use existing public `/api/searchArtists` endpoint to find artist by name
  - [x] Use existing public `/api/artistBio/[id]` endpoint for AI-generated artist biographies  
  - [x] Use existing public `/api/funFacts/[type]` endpoint for song/artist trivia
  - [x] Implement two-step flow: search by name → get bio/facts by ID
  - [x] No proxy server needed - direct API consumption
  - [x] Simple "first result" algorithm for artist disambiguation
- [x] **iOS Network Layer**:
  - [x] `MusicNerdService` with proper error handling and timeouts (25s for MusicNerdNG)
  - [x] Comprehensive debug logging for request/response troubleshooting
  - [x] Fixed critical JSON decoding bug (artist ID String vs Int type mismatch)
  - [x] Network reachability monitoring
  - [x] Retry logic for failed requests
- [x] **Integration Strategy**:
  - [x] Map ShazamKit metadata (artist name) to MusicNerdNG search
  - [x] Handle cases where artist is not found in MusicNerdNG database  
  - [x] Automatic background enrichment with UI status indicators
  - [x] Fallback gracefully when MusicNerdNG APIs are unavailable
  - [x] Cache enrichment data locally to avoid repeated API calls
- [x] **Unit Testing:**
  - [x] Test artist name search and ID resolution
  - [x] Test bio and fun facts API response parsing
  - [x] Test network error handling and retry logic
  - [x] Test caching behavior
  - [x] Mock MusicNerdNG API responses for testing
- [x] **UI Testing:**
  - [x] Test network error states in UI
  - [x] Test loading indicators during API calls
  - [x] Test artist not found scenarios
  - [x] Test offline mode behavior

---

### 🧠 Phase 5: Enrichment & Intelligence ✅
- [x] **Backend Integration**:
  - [x] Integrate OpenAI enrichment with recognition flow
  - [x] MusicNerdService API integration (search, bio, fun facts)
  - [x] Automatic background enrichment after recognition
  - [x] Loading states during enrichment
- [x] **Content Display**:
  - [x] Create match detail view to display enriched content
  - [x] Display artist bio in readable format
  - [x] Display fun facts with proper categorization (lore, bts, activity, surprise)
  - [x] Add navigation from SongMatchCard to detail view
  - [x] Format and style enriched content with Music Nerd branding
  - [x] Fix fun facts parsing (API returns "text" field, not "funFact")
- [x] **Enhanced UI Features**:
  - [x] Expandable content sections in detail view
  - [x] Share enriched content functionality
  - [x] Fix animation conflicts in expandable chevrons
- [x] **Smart Features**:
  - [x] Fallback content for API failures (FallbackSectionView with user-friendly error messages)
  - [x] Content caching for offline viewing
  - [x] Retry mechanism for failed enrichment (retryEnrichment() with exponential backoff)
- [x] **Error Handling**:
  - [x] No match scenarios
  - [x] Network failure recovery (null ID handling, API error parsing)
  - [x] API rate limit handling (comprehensive retry logic with timeouts)
  - [x] Individual content error tracking (bioError, funFactErrors by type)
  - [x] User-friendly error messages and graceful degradation
- [x] **Unit Testing:**
  - [x] Test enrichment data processing and formatting (EnrichmentErrorHandlingTests)
  - [x] Test caching logic for enrichment content
  - [x] Test fallback content selection and error tracking
  - [x] Test error recovery mechanisms (rate limiting, network errors, individual content failures)
  - [x] Test retry scenarios with different error types
- [x] **UI Testing:**
  - [x] Test enrichment loading states (EnrichmentUITests comprehensive suite)
  - [x] Test enriched content display formatting (expandable sections, content display)
  - [x] Test fallback content when enrichment fails (error messages, retry buttons)
  - [x] Test "no match" user experience (empty states, navigation maintenance)
  - [x] Test rate limit handling in UI (user-friendly messaging, retry behavior)

---

### 💾 Phase 6: Data Persistence & History ✅
- [x] **Storage Implementation**:
  - [x] SwiftData setup for match history (SongMatch and EnrichmentData @Model classes)
  - [x] SwiftData model container configuration in app and services
  - [x] Comprehensive CRUD operations with StorageService
  - [x] Migrate in-memory enrichment cache to persistent storage (EnrichmentCacheEntry SwiftData model)
  - [x] Persistent enrichment cache with expiration and cleanup
  - [x] User preferences and settings (auto-enrichment toggle, clear history, export data)
- [x] **History Features**:
  - [x] Scrollable match history list with SongMatchCard components
  - [x] Search and filter capabilities (by title, artist, album, enrichment status, date ranges)
  - [x] Advanced filtering with HistoryFilterView (enrichment status, date presets, custom ranges)
  - [x] Match detail view with full enrichment (existing MatchDetailView integration)
  - [x] Real-time search and filtering with HistoryViewModel
  - [ ] Implement recent matches display in ListeningView (show last 3-5 matches)
  - [ ] Remove sample data from recent matches section in ListeningView
  - [ ] Remove "Found it!" message after successful match recognition
  - [ ] Export/share functionality (deferred - placeholder in Settings UI)
- [x] **Unit Testing:**
  - [x] Test SwiftData persistence and retrieval (SwiftDataPersistenceTests with 10 comprehensive tests)
  - [x] Test CRUD operations, error data persistence, performance with 100 records
  - [x] Test data integrity across app restarts and edge cases
  - [x] Test search and filtering logic (HistoryViewModelTests with 18 comprehensive test methods)
  - [x] Test enrichment cache persistence and expiration (EnrichmentCacheTests)
  - [ ] Test data migration between app versions
  - [ ] Test export data formatting (deferred)
- [ ] **UI Testing:**
  - [ ] Test history list scrolling and performance
  - [ ] Test search functionality with various queries
  - [x] Test match detail view navigation (fixed sheet presentation race condition)
  - [ ] Test filter functionality (filter sheet, enrichment status, date ranges, reset/clear)
  - [ ] Test empty state when no history exists
  - [ ] Test loading states and error handling
  - [ ] Test combined search and filtering workflows
  - [ ] Test export/share workflows (deferred)

---

### 🚀 Phase 7: Polish & App Store Preparation
- [ ] **Data Export/Import Features**:
  - [ ] Implement user data export functionality (JSON format)
  - [ ] Add export options (email, save to files, share)
  - [ ] Consider data import capabilities for backup restoration
- [ ] **UI Polish**:
  - [ ] Responsive design for all device sizes
  - [ ] Dark mode support
  - [ ] Haptic feedback and animations
  - [ ] Accessibility compliance (VoiceOver, Dynamic Type)
- [ ] **App Store Setup**:
  - [ ] App Store Connect project creation
  - [ ] Screenshots and metadata
  - [ ] Privacy policy and terms
- [ ] **TestFlight & Release**:
  - [ ] Internal testing build
  - [ ] External beta testing
  - [ ] App Store submission and review
- [ ] **Unit Testing:**
  - [ ] Test haptic feedback triggers
  - [ ] Test accessibility feature implementations
  - [ ] Test app store compliance validations
- [ ] **UI Testing:**
  - [ ] Final end-to-end user acceptance testing
  - [ ] Test app store screenshot scenarios
  - [ ] Verify all accessibility features work correctly
  - [ ] Test app behavior in low memory/battery conditions
  - [ ] Validate app store review guidelines compliance

## 🎯 Current Focus & Next Steps

**Completed Phases:**
- ✅ **Phase 1** (Foundation & Architecture) - 100% complete
  - ✅ Project setup and folder structure
  - ✅ Core data models defined (`SongMatch`, `EnrichmentData`, error types)
  - ✅ Dependency injection and app configuration
  - ✅ Comprehensive unit testing (40+ tests passing)

- ✅ **Phase 2** (UI/UX Foundation) - 100% complete  
  - ✅ Complete design system with Music Nerd branding
  - ✅ TabView navigation structure (Listen/History/Settings)
  - ✅ All core views implemented with accessibility
  - ✅ All 27 UI tests passing after navigation update
  - ✅ Unit tests fixed and passing

- ✅ **Phase 3** (Music Recognition Core) - 100% complete
  - ✅ Microphone permissions with proper Info.plist descriptions
  - ✅ Real ShazamKit implementation with audio capture and signature generation
  - ✅ Recognition states and UI flow (listening, processing, success, failure)
  - ✅ Complete UI integration with ListeningView
  - ✅ Comprehensive unit and UI testing with safe test skipping
  - ✅ Full SHSessionDelegate implementation for metadata parsing
  - ✅ Audio engine tap lifecycle management (prevents crashes on multiple recognitions)
  - ✅ Enhanced error handling for ShazamKit signature validation
  - ✅ Configurable sample duration setting (3-20 seconds, defaults to 3)
  - ✅ Professional debug logging with timestamps
  - ✅ Production-ready ShazamService with comprehensive error handling

- ✅ **Phase 4** (Backend Services & Integration) - 100% complete
  - ✅ Complete network reachability monitoring with NWPathMonitor
  - ✅ Network status UI indicators and offline banners
  - ✅ Retry logic with exponential backoff for network recovery
  - ✅ All UI tests fixed and timing-independent
  - ✅ NetworkStatusUITests: 100% pass rate (17/17 tests)
  - ✅ RecognitionFlowUITests: 100% pass rate after timing fixes

**Currently:** Phase 6 (Data Persistence & History) - 75% complete
- ✅ Complete SwiftData setup with SongMatch and EnrichmentData persistence
- ✅ Enrichment cache migration to persistent SwiftData storage with expiration
- ✅ Full history UI implementation with search, filtering, and real-time updates
- ✅ Unit testing: 18 tests for history logic, enrichment cache persistence
- ✅ MVVM architecture with HistoryViewModel for proper data management
- ✅ Advanced filtering system with enrichment status and date range filtering
- ⏳ Remaining: UI testing suite, export functionality

**Next:** Complete Phase 6 UI testing and export features, then move to Phase 7

**Previous Phase:**
- ✅ Phase 5 (Enrichment & Intelligence) - 100% COMPLETE!

**Development Philosophy:**
- Build solid architectural foundation before adding features
- Test early and often with real devices and music
- Focus on smooth user experience over feature quantity
- Plan for App Store guidelines from day one

**Success Metrics:**
- Recognition accuracy and speed
- Enrichment content quality and relevance  
- User engagement with history/discovery features
- App Store rating and user retention
