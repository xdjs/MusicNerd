//
//  HistoryView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/5/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""
    @State private var showingMatchDetail = false
    @State private var selectedMatch: SongMatch?
    // Sample data for UI testing - will be replaced with real persistence in Phase 6
    @State private var sampleMatches: [SongMatch] = [
        SongMatch(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            enrichmentData: EnrichmentData(
                artistBio: "British rock band formed in London in 1970",
                songTrivia: "Took 3 weeks to record, considered one of the greatest songs of all time"
            )
        ),
        SongMatch(
            title: "Hotel California",
            artist: "Eagles",
            enrichmentData: EnrichmentData(
                artistBio: "American rock band formed in Los Angeles in 1971"
            )
        ),
        SongMatch(
            title: "Stairway to Heaven",
            artist: "Led Zeppelin"
        ),
        SongMatch(
            title: "Sweet Child O' Mine",
            artist: "Guns N' Roses"
        )
    ]
    
    var filteredMatches: [SongMatch] {
        if searchText.isEmpty {
            return sampleMatches
        } else {
            return sampleMatches.filter { match in
                match.title.localizedCaseInsensitiveContains(searchText) ||
                match.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                        
                        TextField("Search your matches...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .accessibilityIdentifier("search-field")
                    }
                    .padding(CGFloat.MusicNerd.md)
                    .background(Color.MusicNerd.surface)
                    .cornerRadius(12)
                    
                    if !searchText.isEmpty {
                        Button("Cancel") {
                            searchText = ""
                        }
                        .foregroundColor(Color.MusicNerd.primary)
                        .accessibilityIdentifier("search-cancel-button")
                    }
                }
                .padding(CGFloat.MusicNerd.screenMargin)
                .background(Color.MusicNerd.background)
                
                // Content
                if filteredMatches.isEmpty {
                    // Empty State
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        Spacer()
                        
                        Image(systemName: searchText.isEmpty ? "music.note.list" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(Color.MusicNerd.textSecondary)
                        
                        Text(searchText.isEmpty ? "No Matches Yet" : "No Results")
                            .musicNerdStyle(.headlineLarge())
                        
                        Text(searchText.isEmpty 
                             ? "Start listening to music to build your collection"
                             : "Try searching for a different song or artist")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            .multilineTextAlignment(.center)
                        
                        if searchText.isEmpty {
                            MusicNerdButton(
                                title: "Start Listening",
                                action: {
                                    // TODO: Navigate to listening tab
                                },
                                style: .secondary,
                                size: .medium,
                                icon: "waveform"
                            )
                            .disabled(true)
                            .accessibilityIdentifier("start-listening-button")
                        }
                        
                        Spacer()
                    }
                    .padding(CGFloat.MusicNerd.screenMargin)
                } else {
                    // Sample Matches List (will be replaced with real data in Phase 6)
                    ScrollView {
                        LazyVStack(spacing: CGFloat.MusicNerd.md) {
                            ForEach(Array(filteredMatches.enumerated()), id: \.element.id) { index, match in
                                SongMatchCard(match: match) {
                                    // Sample data - no action until Phase 6 persistence
                                }
                                .disabled(true)
                                .opacity(0.6)
                                .accessibilityIdentifier("history-match-\(index)")
                            }
                        }
                        .padding(CGFloat.MusicNerd.screenMargin)
                    }
                }
            }
            .background(Color.MusicNerd.background)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        // TODO: Implement export functionality
                    }
                    .foregroundColor(Color.MusicNerd.textSecondary)
                    .disabled(true)
                    .accessibilityIdentifier("export-button")
                }
            }
        }
        .sheet(isPresented: $showingMatchDetail) {
            if let match = selectedMatch {
                MatchDetailView(match: match)
            }
        }
    }
}

#Preview {
    HistoryView()
}