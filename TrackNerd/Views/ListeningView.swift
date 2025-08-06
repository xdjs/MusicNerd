//
//  ListeningView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/5/25.
//

import SwiftUI

struct ListeningView: View {
    @State private var isListening = false
    @State private var permissionStatus: PermissionStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var recognitionState: RecognitionState = .idle
    @State private var lastMatch: SongMatch?
    @State private var errorMessage: String?
    
    private let services = DefaultServiceContainer.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CGFloat.MusicNerd.lg) {
                    // Header Section
                    VStack(spacing: CGFloat.MusicNerd.md) {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 80))
                            .foregroundColor(Color.MusicNerd.primary)
                        
                        Text("What's Playing?")
                            .musicNerdStyle(.displayLarge())
                        
                        Text("Tap to identify any song around you")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, CGFloat.MusicNerd.xl)
                    
                    // Main Listen Button
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        MusicNerdButton(
                            title: buttonTitle,
                            action: handleListenTap,
                            style: .primary,
                            size: .large,
                            isLoading: isListening,
                            icon: isListening ? "waveform" : "mic"
                        )
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
                                
                                if let errorMessage = errorMessage {
                                    Text(errorMessage)
                                        .musicNerdStyle(.bodyMedium(color: Color.red))
                                        .multilineTextAlignment(.center)
                                        .transition(.opacity)
                                }
                            }
                        }
                        
                        // Recognition Result
                        if let match = lastMatch {
                            VStack(spacing: CGFloat.MusicNerd.md) {
                                Text("Found It!")
                                    .musicNerdStyle(.headlineLarge())
                                    .foregroundColor(Color.MusicNerd.primary)
                                
                                SongMatchCard(match: match) {
                                    // TODO: Navigate to match detail
                                }
                                .accessibilityIdentifier("recognition-result")
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // Recent Matches Section
                    VStack(spacing: CGFloat.MusicNerd.md) {
                        HStack {
                            Text("Recent Matches")
                                .musicNerdStyle(.headlineLarge())
                            
                            Spacer()
                            
                            Button("See All") {
                                // TODO: Navigate to history
                            }
                            .foregroundColor(Color.MusicNerd.primary)
                            .accessibilityIdentifier("see-all-button")
                        }
                        
                        // Sample matches (will be replaced with real data)
                        SongMatchCard(
                            match: SongMatch(
                                title: "Bohemian Rhapsody",
                                artist: "Queen",
                                enrichmentData: EnrichmentData(
                                    artistBio: "British rock band formed in London in 1970"
                                )
                            )
                        ) {
                            // TODO: Navigate to match detail
                        }
                        .accessibilityIdentifier("recent-match-0")
                        
                        SongMatchCard(
                            match: SongMatch(
                                title: "Hotel California",
                                artist: "Eagles"
                            )
                        ) {
                            // TODO: Navigate to match detail
                        }
                        .accessibilityIdentifier("recent-match-1")
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
        .onAppear {
            checkPermissionStatus()
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("TrackNerd needs microphone access to identify songs. Please enable it in Settings.")
        }
    }
    
    private var buttonTitle: String {
        switch permissionStatus {
        case .notDetermined:
            return "Start Listening"
        case .granted:
            if isListening {
                switch recognitionState {
                case .idle:
                    return "Start Listening"
                case .listening:
                    return "Listening..."
                case .processing:
                    return "Recognizing..."
                case .success:
                    return "Listen Again"
                case .failure:
                    return "Try Again"
                }
            } else {
                return "Start Listening"
            }
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
    
    private func handleListenTap() {
        Task {
            await requestPermissionAndListen()
        }
    }
    
    private func requestPermissionAndListen() async {
        do {
            permissionStatus = try await services.permissionService.requestMicrophonePermission()
            if permissionStatus == .granted {
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
                    }
                    
                    let result = await services.shazamService.startListening()
                    
                    await MainActor.run {
                        isListening = false
                        
                        switch result {
                        case .success(let match):
                            lastMatch = match
                            recognitionState = .success(match)
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
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

#Preview {
    ListeningView()
}