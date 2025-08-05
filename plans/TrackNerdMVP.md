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

### 🎨 Phase 2: UI/UX Foundation
- [x] **Design system setup:**
  - [x] Music Nerd color palette and typography
  - [x] Custom UI components (buttons, cards, loading states)
  - [x] Consistent spacing and styling
- [ ] Core navigation structure:
  - [ ] Main listening view
  - [ ] History/library view
  - [ ] Settings view
- [ ] Create wireframes for key screens
- [ ] Implement base view components with proper accessibility
- [x] **Unit Testing:**
  - [x] Test custom UI component logic and state
  - [x] Test view model initialization and data binding
  - [x] Test navigation routing logic
- [x] **UI Testing:**
  - [x] Test tab navigation between main sections
  - [x] Verify accessibility identifiers on all components
  - [x] Test responsive layout on different device sizes
  - [x] Test dark mode switching (if implemented)

---

### 🔌 Phase 3: Backend Services & Integration
- [ ] **OpenAI Proxy Server**:
  - [ ] Create `/enrich` endpoint (title + artist → enrichment)
  - [ ] Design GPT prompts for artist bios, song trivia, related content
  - [ ] Add response caching and rate limiting
  - [ ] Deploy and test endpoint
- [ ] **iOS Network Layer**:
  - [ ] `APIService` with proper error handling
  - [ ] `OpenAIService` to call enrichment endpoint
  - [ ] Network reachability monitoring
  - [ ] Retry logic and timeout handling
- [ ] **Unit Testing:**
  - [ ] Test API service request/response parsing
  - [ ] Test network error handling and retry logic
  - [ ] Test reachability monitoring
  - [ ] Mock OpenAI service responses for testing
- [ ] **UI Testing:**
  - [ ] Test network error states in UI
  - [ ] Test loading indicators during API calls
  - [ ] Test offline mode behavior

---

### 🎙 Phase 4: Music Recognition Core
- [ ] **Permissions & Setup**:
  - [ ] Request microphone permission with proper messaging
  - [ ] Add Info.plist descriptions for privacy
- [ ] **ShazamKit Integration**:
  - [ ] `ShazamService` with `SHSignatureGenerator`
  - [ ] `SHSession` for catalog matching
  - [ ] Parse metadata (title, artist, artworkURL, AppleMusicID)
  - [ ] Handle recognition states (listening, processing, success, failure)
- [ ] **Recognition UI**:
  - [ ] Listening animation (waveform/pulse)
  - [ ] Recognition results display
  - [ ] Audio visualization during capture
- [ ] **Unit Testing:**
  - [ ] Test ShazamService state management
  - [ ] Test metadata parsing from ShazamKit responses
  - [ ] Test permission handling logic
  - [ ] Mock ShazamKit for deterministic testing
- [ ] **UI Testing:**
  - [ ] Test microphone permission flow
  - [ ] Test recognition button interactions
  - [ ] Test listening state animations
  - [ ] Test recognition success/failure UI states
  - [ ] Test results display with sample data

---

### 🧠 Phase 5: Enrichment & Intelligence
- [ ] **Content Enhancement**:
  - [ ] Integrate OpenAI enrichment with recognition flow
  - [ ] Display enriched content (artist bio, song context, trivia)
  - [ ] Related songs/artists recommendations
- [ ] **Smart Features**:
  - [ ] Loading states during enrichment
  - [ ] Fallback content for API failures
  - [ ] Content caching for offline viewing
- [ ] **Error Handling**:
  - [ ] No match scenarios
  - [ ] Network failure recovery
  - [ ] API rate limit handling
- [ ] **Unit Testing:**
  - [ ] Test enrichment data processing and formatting
  - [ ] Test caching logic for enrichment content
  - [ ] Test fallback content selection
  - [ ] Test error recovery mechanisms
- [ ] **UI Testing:**
  - [ ] Test enrichment loading states
  - [ ] Test enriched content display formatting
  - [ ] Test fallback content when enrichment fails
  - [ ] Test "no match" user experience
  - [ ] Test rate limit handling in UI

---

### 💾 Phase 6: Data Persistence & History
- [ ] **Storage Implementation**:
  - [ ] SwiftData setup for match history
  - [ ] Local storage for enrichment cache
  - [ ] User preferences and settings
- [ ] **History Features**:
  - [ ] Scrollable match history list
  - [ ] Search and filter capabilities
  - [ ] Match detail view with full enrichment
  - [ ] Export/share functionality
- [ ] **Unit Testing:**
  - [ ] Test SwiftData persistence and retrieval
  - [ ] Test search and filtering logic
  - [ ] Test data migration between app versions
  - [ ] Test export data formatting
- [ ] **UI Testing:**
  - [ ] Test history list scrolling and performance
  - [ ] Test search functionality with various queries
  - [ ] Test match detail view navigation
  - [ ] Test export/share workflows
  - [ ] Test empty state when no history exists

---

### 🧪 Phase 7: Comprehensive Testing & Quality Assurance
- [ ] **Unit Testing Consolidation**:
  - [ ] Achieve 80%+ code coverage across all services
  - [ ] Comprehensive service layer tests (ShazamKit, OpenAI, Storage)
  - [ ] Model validation and utility function tests
  - [ ] Mock implementations for all external dependencies
  - [ ] Edge case and error condition testing
- [ ] **UI Testing Consolidation**:
  - [ ] Complete user journey automation (recognition → enrichment → history)
  - [ ] Cross-device UI testing (iPhone, iPad, different sizes)
  - [ ] Accessibility testing with VoiceOver
  - [ ] Performance UI testing (smooth scrolling, animations)
- [ ] **Integration Testing**:
  - [ ] End-to-end recognition flow with real audio
  - [ ] Network layer integration with staging/production APIs
  - [ ] Data persistence integration across app sessions
- [ ] **Performance & Stress Testing**:
  - [ ] Memory usage during extended audio capture
  - [ ] Battery impact assessment over time
  - [ ] Large dataset handling (1000+ matches)
  - [ ] Concurrent recognition attempts
- [ ] **Security & Privacy Testing**:
  - [ ] Audio data handling and disposal
  - [ ] Network request security validation
  - [ ] User data privacy compliance

---

### 🚀 Phase 8: Polish & App Store Preparation  
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

**Currently:** Phase 1 (Foundation & Architecture) - 100% complete ✅
- ✅ Project setup and folder structure
- ✅ Core data models defined (`SongMatch`, `EnrichmentData`, error types)
- ✅ Dependency injection and app configuration
- ✅ Comprehensive unit testing (40/40 tests passing)
- ✅ UI testing (6/6 tests passing)

**Immediate Priorities:**
1. Begin Phase 2: UI/UX Foundation
2. Design system setup (colors, typography, components)
3. Core navigation structure implementation

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
