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
                            LoadingStateView(
                                message: "Listening for music...",
                                loadingType: .waveform
                            )
                            .frame(height: 120)
                            .transition(.opacity)
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
            return isListening ? "Listening..." : "Start Listening"
        case .denied, .restricted:
            return "Enable Microphone"
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
                isListening.toggle()
                // TODO: Integrate with ShazamKit
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