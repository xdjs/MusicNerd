//
//  ListeningView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/5/25.
//

import SwiftUI

struct ListeningView: View {
    @Binding var selectedTab: ContentView.Tab
    @State private var isListening = false
    @State private var permissionStatus: PermissionStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var recognitionState: RecognitionState = .idle
    @State private var lastMatch: SongMatch?
    @State private var errorMessage: String?
    @State private var showDebugInfo: Bool = AppSettings.shared.showDebugInfo
    @State private var sampleDuration: TimeInterval = AppSettings.shared.sampleDuration
    @State private var isEnriching: Bool = false
    @State private var recentMatches: [SongMatch] = []
    @State private var selectedMatchForDetail: SongMatch? = nil
    @StateObject private var reachabilityService = NetworkReachabilityService.shared
    @State private var elapsedTime: TimeInterval = 0
    @State private var lastElapsedTime: TimeInterval? = nil
    @State private var matchedElapsedTime: TimeInterval? = nil
    @State private var elapsedTimer: Timer? = nil
    
    private let services = DefaultServiceContainer.shared
    private let settings = AppSettings.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CGFloat.MusicNerd.lg) {
                    // Header Section
                    VStack(spacing: CGFloat.MusicNerd.md) {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 80))
                            .foregroundColor(Color.MusicNerd.primary)
                        
                        Text("Hear. ID. Nerd out.")
                            .musicNerdStyle(.displayLarge())
                        
                        Text("Tap to identify any song around you")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            .multilineTextAlignment(.center)
                        
                        // Network status indicator
                        HStack {
                            Spacer()
                            NetworkStatusIndicator()
                        }
                        .padding(.horizontal, CGFloat.MusicNerd.md)
                        
                        // Debug info display
                        if showDebugInfo {
                            Text("Sample Duration: \(AppSettings.formatDuration(sampleDuration))")
                                .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
                                .padding(.horizontal, CGFloat.MusicNerd.md)
                                .padding(.vertical, CGFloat.MusicNerd.xs)
                                .background(Color.MusicNerd.accent.opacity(0.1))
                                .cornerRadius(CGFloat.BorderRadius.xs)
                                .accessibilityIdentifier("debug-sample-duration")

                            // On failed match, show total time listened underneath the sample duration label
                            if case .failure = recognitionState, let total = lastElapsedTime {
                                Text("Listened: \(formatSeconds(total))")
                                    .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
                                    .padding(.horizontal, CGFloat.MusicNerd.md)
                                    .padding(.vertical, CGFloat.MusicNerd.xs)
                                    .background(Color.MusicNerd.accent.opacity(0.06))
                                    .cornerRadius(CGFloat.BorderRadius.xs)
                                    .accessibilityIdentifier("debug-elapsed-failure")
                            }
                        }
                    }
                    .padding(.top, CGFloat.MusicNerd.xl)
                    
                    // Network status banner (offline)
                    NetworkStatusBanner()
                    
                    // Main Listen Button
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        MusicNerdButton(
                            title: buttonTitle,
                            action: handleListenTap,
                            style: .primary,
                            size: .large,
                            isLoading: false,
                            icon: isListening ? "waveform" : "mic"
                        )
                        .disabled(!reachabilityService.isConnected && !isListening)
                        .opacity((!reachabilityService.isConnected && !isListening) ? 0.6 : 1.0)
                        .accessibilityIdentifier("listen-button")
                        
                        if isListening {
                            VStack(spacing: CGFloat.MusicNerd.md) {
                                // Placeholder artwork during listening
                                AlbumArtworkView(url: nil, size: 120)
                                    .transition(.scale.combined(with: .opacity))
                                
                                LoadingStateView(
                                    message: loadingMessage,
                                    loadingType: .waveform
                                )
                                .frame(height: 60)
                                .transition(.opacity)

                                // Show live elapsed time during listening (debug only)
                                if showDebugInfo {
                                    Text("Elapsed: \(formatSeconds(elapsedTime))")
                                        .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
                                        .accessibilityIdentifier("debug-elapsed-listening")
                                }
                                
                                if let errorMessage = errorMessage {
                                    Text(errorMessage)
                                        .musicNerdStyle(.bodyMedium(color: Color.red))
                                        .multilineTextAlignment(.center)
                                        .transition(.opacity)
                                }
                            }
                        }
                        
                        // Recognition Result
                        if let match = lastMatch, case .success(let recognized) = recognitionState, recognized.id == match.id {
                            VStack(spacing: CGFloat.MusicNerd.md) {
                                SongMatchCard(match: match) {
                                    selectedMatchForDetail = match
                                }
                                .accessibilityIdentifier("recognition-result")
                                
                                // Enrichment Status
                                if isEnriching {
                                    HStack(spacing: CGFloat.MusicNerd.xs) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Getting music nerd insights...")
                                            .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
                                    }
                                    .transition(.opacity)
                                } else if match.hasEnrichment {
                                    HStack(spacing: CGFloat.MusicNerd.xs) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(Color.MusicNerd.primary)
                                            .font(.caption)
                                        Text("Enhanced with Music Nerd insights!")
                                            .musicNerdStyle(.caption(color: Color.MusicNerd.primary))
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // Recent Matches Section
                    if !recentMatches.isEmpty {
                        VStack(spacing: CGFloat.MusicNerd.md) {
                            HStack {
                                Text("Recent Matches")
                                    .musicNerdStyle(.headlineLarge())
                                
                                Spacer()
                                
                                Button("See All") {
                                    selectedTab = .history
                                }
                                .foregroundColor(Color.MusicNerd.primary)
                                .accessibilityIdentifier("see-all-button")
                            }
                            
                            ForEach(recentMatches.prefix(5)) { match in
                                SongMatchCard(match: match) {
                                    // Navigate to match detail without surfacing card above the button
                                    selectedMatchForDetail = match
                                }
                                .accessibilityIdentifier("recent-match-\(match.id)")
                            }
                        }
                    }
                    
                    Spacer(minLength: CGFloat.MusicNerd.xl)
                }
                .padding(CGFloat.MusicNerd.screenMargin)
            }
            .background(Color.MusicNerd.background)
            .navigationTitle("Listen")
            .navigationBarTitleDisplayMode(.inline)
        }
        .animation(.easeInOut(duration: 0.3), value: isListening)
        .animation(.easeInOut(duration: 0.3), value: lastMatch)
        .animation(.easeInOut(duration: 0.2), value: showDebugInfo)
        .onAppear {
            checkPermissionStatus()
            updateDebugSettings()
            Task {
                await loadRecentMatches()
            }
        }
        .onChange(of: settings.showDebugInfo) { _, newValue in
            showDebugInfo = newValue
        }
        .onChange(of: settings.sampleDuration) { _, newValue in
            sampleDuration = newValue
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Music Nerd ID needs microphone access to identify songs. Please enable it in Settings.")
        }
        .sheet(item: $selectedMatchForDetail, onDismiss: { selectedMatchForDetail = nil }) { match in
            MatchDetailView(match: match)
        }
    }
    
    private var buttonTitle: String {
        if isListening {
            return "Stop Listening"
        }
        // Check network connectivity first
        if !reachabilityService.isConnected && !isListening {
            return "No Internet Connection"
        }
        
        switch permissionStatus {
        case .notDetermined:
            return "Start Listening"
        case .granted:
            return "Start Listening"
        case .denied, .restricted:
            return "Enable Microphone"
        }
    }
    
    private var loadingMessage: String {
        switch recognitionState {
        case .listening:
            return "Listening for music..."
        case .processing:
            return "Identifying song..."
        default:
            return "Listening for music..."
        }
    }
    
    private func checkPermissionStatus() {
        permissionStatus = services.permissionService.checkMicrophonePermission()
    }
    
    private func updateDebugSettings() {
        showDebugInfo = settings.showDebugInfo
        sampleDuration = settings.sampleDuration
    }
    
    @MainActor
    private func loadRecentMatches() async {
        let result = await services.storageService.loadMatches()
        switch result {
        case .success(let matches):
            // Take only the first 5 matches (already sorted by matchedAt desc in StorageService)
            recentMatches = Array(matches.prefix(5))
            print("Loaded \(recentMatches.count) recent matches for ListeningView")
        case .failure(let error):
            print("Failed to load recent matches: \(error.localizedDescription)")
            recentMatches = []
        }
    }
    
    private func handleListenTap() {
        // Prevent listening when offline (unless already listening)
        guard reachabilityService.isConnected || isListening else {
            errorMessage = "Music recognition requires an internet connection"
            return
        }
        
        if isListening {
            // Explicit cancel path
            services.shazamService.stopListening()
            stopElapsedTimer()
            lastElapsedTime = elapsedTime
            isListening = false
            recognitionState = .idle
            errorMessage = nil
        } else {
            Task {
                await requestPermissionAndListen()
            }
        }
    }
    
    private func requestPermissionAndListen() async {
        do {
            permissionStatus = try await services.permissionService.requestMicrophonePermission()
            if permissionStatus == .granted {
                // Ensure all playback is stopped before beginning microphone capture to avoid session conflicts
                services.appleMusicService.stopAllPlayback()
                if isListening {
                    // Stop current recognition
                    services.shazamService.stopListening()
                    await MainActor.run {
                        isListening = false
                        recognitionState = .idle
                        errorMessage = nil
                    }
                } else {
                    // Start recognition
                    await MainActor.run {
                        isListening = true
                        lastMatch = nil
                        errorMessage = nil
                        recognitionState = .listening
                        matchedElapsedTime = nil
                        lastElapsedTime = nil
                        startElapsedTimer()
                    }
                    
                    let result = await services.shazamService.startListening()
                    
                    await MainActor.run {
                        isListening = false
                        stopElapsedTimer()
                        lastElapsedTime = elapsedTime
                        
                        switch result {
                        case .success(let match):
                            lastMatch = match
                            recognitionState = .success(match)
                            matchedElapsedTime = lastElapsedTime
                            
                            // Save the match immediately (before enrichment)
                            Task {
                                await saveMatchToHistory(match)
                                // Refresh recent matches to include the new match
                                await loadRecentMatches()
                            }
                            
                            // Present the detail view immediately
                            selectedMatchForDetail = match
                            
                            // Automatically start enrichment in background
                            Task {
                                await enrichSongMatch(match)
                            }
                            
                        case .failure(let error):
                            recognitionState = .failure(error)
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                showingPermissionAlert = true
            }
        }
    }
    
    @MainActor
    private func saveMatchToHistory(_ match: SongMatch) async {
        let saveResult = await services.storageService.save(match)
        switch saveResult {
        case .success:
            print("Song match saved to history: '\(match.title)' by '\(match.artist)'")
        case .failure(let error):
            print("Failed to save song match to history: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func enrichSongMatch(_ match: SongMatch) async {
        // Only enrich if not already enriched
        guard match.enrichmentData == nil else {
            print("Song already has enrichment data, skipping.")
            return
        }
        
        isEnriching = true
        print("Starting enrichment for: '\(match.title)' by '\(match.artist)'")
        
        let enrichmentResult = await services.openAIService.enrichSong(match)
        
        switch enrichmentResult {
        case .success(let enrichmentData):
            print("Enrichment successful - updating song match")
            
            // Update the match with enrichment data
            match.enrichmentData = enrichmentData
            
            // Save the updated enriched match
            let saveResult = await services.storageService.save(match)
            switch saveResult {
            case .success:
                print("Enriched song match updated successfully")
                
                // Update UI to reflect enrichment
                if lastMatch?.id == match.id {
                    lastMatch = match
                }
                
            case .failure(let error):
                print("Failed to update enriched song match: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            print("Enrichment failed: \(error.localizedDescription)")
        }
        
        isEnriching = false
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }

    // MARK: - Elapsed Time Helpers
    private func startElapsedTimer() {
        stopElapsedTimer()
        elapsedTime = 0
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
        }
        RunLoop.main.add(elapsedTimer!, forMode: .common)
    }
    
    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }
    
    private func formatSeconds(_ t: TimeInterval) -> String {
        String(format: "%.2fs", t)
    }
}

#Preview {
    ListeningView(selectedTab: .constant(.listen))
}
