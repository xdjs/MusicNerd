//
//  ContentView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: CGFloat.MusicNerd.lg) {
                // Header Section
                VStack(spacing: CGFloat.MusicNerd.md) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(Color.MusicNerd.primary)
                    
                    Text("Music Nerd")
                        .musicNerdStyle(.displayLarge())
                    
                    Text("Discover the stories behind your music")
                        .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, CGFloat.MusicNerd.xl)
                
                // Example Cards Section
                VStack(spacing: CGFloat.MusicNerd.md) {
                    Text("Recent Matches")
                        .musicNerdStyle(.headlineLarge())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Sample Song Match Cards
                    SongMatchCard(
                        match: SongMatch(
                            title: "Bohemian Rhapsody",
                            artist: "Queen",
                            enrichmentData: EnrichmentData(
                                artistBio: "British rock band formed in London in 1970"
                            )
                        )
                    ) {
                        // Handle tap
                    }
                    
                    SongMatchCard(
                        match: SongMatch(
                            title: "Hotel California",
                            artist: "Eagles"
                        )
                    ) {
                        // Handle tap
                    }
                    
                    LoadingCard()
                }
                
                // Example Buttons Section
                VStack(spacing: CGFloat.MusicNerd.md) {
                    Text("Actions")
                        .musicNerdStyle(.headlineLarge())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    MusicNerdButton(
                        title: "Start Listening",
                        action: {
                            isLoading.toggle()
                        },
                        style: .primary,
                        size: .large,
                        isLoading: isLoading,
                        icon: "waveform"
                    )
                    
                    HStack(spacing: CGFloat.MusicNerd.sm) {
                        MusicNerdButton(
                            title: "History",
                            action: {},
                            style: .secondary,
                            size: .medium,
                            icon: "clock"
                        )
                        
                        MusicNerdButton(
                            title: "Settings",
                            action: {},
                            style: .outline,
                            size: .medium,
                            icon: "gear"
                        )
                    }
                }
                
                // Example Loading States Section
                if isLoading {
                    VStack(spacing: CGFloat.MusicNerd.md) {
                        Text("Listening...")
                            .musicNerdStyle(.headlineMedium())
                        
                        LoadingStateView(
                            message: "Identifying music...",
                            loadingType: .waveform
                        )
                        .frame(height: 100)
                    }
                    .transition(.opacity)
                }
                
                // Example Card Styles
                VStack(spacing: CGFloat.MusicNerd.md) {
                    Text("Card Examples")
                        .musicNerdStyle(.headlineLarge())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    MusicNerdCard(style: .default) {
                        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                            Text("Default Card")
                                .musicNerdStyle(.titleMedium())
                            Text("This is a default card with subtle shadow")
                                .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                        }
                    }
                    
                    MusicNerdCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                            Text("Elevated Card")
                                .musicNerdStyle(.titleMedium())
                            Text("This card has more pronounced shadow")
                                .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                        }
                    }
                    
                    MusicNerdCard(style: .outline) {
                        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                            Text("Outline Card")
                                .musicNerdStyle(.titleMedium())
                            Text("This card has a pink border")
                                .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                        }
                    }
                }
                
                Spacer(minLength: CGFloat.MusicNerd.xl)
            }
            .padding(CGFloat.MusicNerd.screenMargin)
        }
        .background(Color.MusicNerd.background)
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

#Preview {
    ContentView()
}
