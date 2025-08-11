//
//  HistoryView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/5/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showingMatchDetail = false
    @State private var selectedMatch: SongMatch?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                        
                        TextField("Search your matches...", text: $viewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .accessibilityIdentifier("search-field")
                    }
                    .padding(CGFloat.MusicNerd.md)
                    .background(Color.MusicNerd.surface)
                    .cornerRadius(12)
                    
                    if !viewModel.searchText.isEmpty {
                        Button("Cancel") {
                            viewModel.clearSearch()
                        }
                        .foregroundColor(Color.MusicNerd.primary)
                        .accessibilityIdentifier("search-cancel-button")
                    }
                }
                .padding(CGFloat.MusicNerd.screenMargin)
                .background(Color.MusicNerd.background)
                
                // Filter Bar (if filters are active)
                if viewModel.hasActiveFilters {
                    HStack {
                        Text("\(viewModel.activeFilterCount) filter\(viewModel.activeFilterCount == 1 ? "" : "s") applied")
                            .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        
                        Spacer()
                        
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .foregroundColor(Color.MusicNerd.primary)
                        .font(.system(size: 14, weight: .medium))
                        .accessibilityIdentifier("clear-filters-button")
                    }
                    .padding(.horizontal, CGFloat.MusicNerd.screenMargin)
                    .padding(.vertical, CGFloat.MusicNerd.xs)
                    .background(Color.MusicNerd.surface)
                }
                
                // Content
                if viewModel.isLoading {
                    // Loading State
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        Spacer()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.MusicNerd.primary)
                        
                        Text("Loading your matches...")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                        
                        Spacer()
                    }
                    .padding(CGFloat.MusicNerd.screenMargin)
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(Color.MusicNerd.textSecondary)
                        
                        Text("Something Went Wrong")
                            .musicNerdStyle(.headlineLarge())
                        
                        Text(errorMessage)
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            .multilineTextAlignment(.center)
                        
                        MusicNerdButton(
                            title: "Try Again",
                            action: {
                                Task {
                                    await viewModel.refreshMatches()
                                }
                            },
                            style: .secondary,
                            size: .medium,
                            icon: "arrow.clockwise"
                        )
                        .accessibilityIdentifier("retry-button")
                        
                        Spacer()
                    }
                    .padding(CGFloat.MusicNerd.screenMargin)
                } else if !viewModel.hasSearchResults {
                    // Empty State
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        Spacer()
                        
                        Image(systemName: viewModel.searchText.isEmpty ? "music.note.list" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(Color.MusicNerd.textSecondary)
                        
                        Text(viewModel.searchText.isEmpty ? "No Matches Yet" : "No Results")
                            .musicNerdStyle(.headlineLarge())
                        
                        Text(viewModel.searchText.isEmpty 
                             ? "Start listening to music to build your collection"
                             : "Try searching for a different song or artist")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            .multilineTextAlignment(.center)
                        
                        if viewModel.searchText.isEmpty {
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
                    // Match History List
                    ScrollView {
                        LazyVStack(spacing: CGFloat.MusicNerd.md) {
                            ForEach(Array(viewModel.filteredMatches.enumerated()), id: \.element.id) { index, match in
                                SongMatchCard(match: match) {
                                    selectedMatch = match
                                    showingMatchDetail = true
                                }
                                .accessibilityIdentifier("history-match-\(index)")
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteMatch(match)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(CGFloat.MusicNerd.screenMargin)
                    }
                    .refreshable {
                        await viewModel.refreshMatches()
                    }
                }
            }
            .background(Color.MusicNerd.background)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.toggleFilter()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(viewModel.hasActiveFilters ? Color.MusicNerd.primary : Color.MusicNerd.textSecondary)
                            
                            if viewModel.hasActiveFilters {
                                Text("\(viewModel.activeFilterCount)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.MusicNerd.primary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .accessibilityIdentifier("filter-button")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        // TODO: Implement export functionality
                    }
                    .foregroundColor(Color.MusicNerd.textSecondary)
                    .disabled(viewModel.isEmpty)
                    .accessibilityIdentifier("export-button")
                }
            }
            .task {
                await viewModel.loadMatches()
            }
        }
        .sheet(isPresented: $showingMatchDetail) {
            if let match = selectedMatch {
                MatchDetailView(match: match)
            }
        }
        .sheet(isPresented: $viewModel.showingFilter) {
            HistoryFilterView(
                filterCriteria: $viewModel.filterCriteria,
                isPresented: $viewModel.showingFilter
            )
        }
    }
}

#Preview {
    HistoryView()
}