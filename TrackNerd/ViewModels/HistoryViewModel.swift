//
//  HistoryViewModel.swift
//  TrackNerd
//
//  Created by Claude on 8/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var matches: [SongMatch] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var filterCriteria: FilterCriteria = FilterCriteria()
    @Published var showingFilter: Bool = false
    
    private let storageService: StorageServiceProtocol
    
    init(storageService: StorageServiceProtocol? = nil) {
        self.storageService = storageService ?? DefaultServiceContainer.shared.storageService
    }
    
    // MARK: - Computed Properties
    
    var filteredMatches: [SongMatch] {
        var filtered = matches
        
        // Apply search filter first
        if !searchText.isEmpty {
            filtered = filtered.filter { match in
                match.title.localizedCaseInsensitiveContains(searchText) ||
                match.artist.localizedCaseInsensitiveContains(searchText) ||
                (match.album?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        
        // Apply filter criteria
        filtered = applyFilterCriteria(to: filtered)
        
        return filtered
    }
    
    var isEmpty: Bool {
        return matches.isEmpty
    }
    
    var hasSearchResults: Bool {
        return !filteredMatches.isEmpty
    }
    
    var hasActiveFilters: Bool {
        return filterCriteria.isActive
    }
    
    var activeFilterCount: Int {
        var count = 0
        if filterCriteria.enrichmentStatus != .all { count += 1 }
        if filterCriteria.startDate != nil || filterCriteria.endDate != nil { count += 1 }
        return count
    }
    
    // MARK: - Public Methods
    
    func loadMatches() async {
        isLoading = true
        errorMessage = nil
        
        let result = await storageService.loadMatches()
        
        switch result {
        case .success(let loadedMatches):
            matches = loadedMatches
            logWithTimestamp("Loaded \(loadedMatches.count) matches from storage")
        case .failure(let error):
            errorMessage = "Failed to load match history: \(error.localizedDescription)"
            logWithTimestamp("Failed to load matches: \(error)")
            matches = []
        }
        
        isLoading = false
    }
    
    func refreshMatches() async {
        logWithTimestamp("Refreshing match history")
        await loadMatches()
    }
    
    func deleteMatch(_ match: SongMatch) async {
        let result = await storageService.delete(match)
        
        switch result {
        case .success:
            // Remove from local array
            matches.removeAll { $0.id == match.id }
            logWithTimestamp("Deleted match: \(match.title) by \(match.artist)")
        case .failure(let error):
            errorMessage = "Failed to delete match: \(error.localizedDescription)"
            logWithTimestamp("Failed to delete match: \(error)")
        }
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Search and Filter Methods
    
    func searchMatches(with query: String) {
        searchText = query
        logWithTimestamp("Searching matches with query: '\(query)'")
    }
    
    func applyFilterCriteria(to matches: [SongMatch]) -> [SongMatch] {
        var filtered = matches
        
        // Filter by enrichment status
        switch filterCriteria.enrichmentStatus {
        case .all:
            break
        case .enriched:
            filtered = filtered.filter { $0.enrichmentData != nil }
        case .notEnriched:
            filtered = filtered.filter { $0.enrichmentData == nil }
        }
        
        // Filter by date range
        if let startDate = filterCriteria.startDate {
            filtered = filtered.filter { $0.matchedAt >= startDate }
        }
        
        if let endDate = filterCriteria.endDate {
            filtered = filtered.filter { $0.matchedAt <= endDate }
        }
        
        if hasActiveFilters {
            logWithTimestamp("Applied filters - \(filtered.count) matches remain from \(matches.count) total")
        }
        
        return filtered
    }
    
    func clearFilters() {
        filterCriteria = FilterCriteria()
        logWithTimestamp("Cleared all filters")
    }
    
    func toggleFilter() {
        showingFilter = true
    }
    
    // MARK: - Private Helpers
    
    private func logWithTimestamp(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] HistoryViewModel: \(message)")
    }
}

// MARK: - Supporting Types

enum EnrichmentStatusFilter: String, CaseIterable {
    case all = "All"
    case enriched = "With Insights"
    case notEnriched = "Without Insights"
}

struct FilterCriteria {
    var enrichmentStatus: EnrichmentStatusFilter = .all
    var startDate: Date?
    var endDate: Date?
    
    var isActive: Bool {
        return enrichmentStatus != .all || startDate != nil || endDate != nil
    }
}