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
    
    private let storageService: StorageServiceProtocol
    
    init(storageService: StorageServiceProtocol? = nil) {
        self.storageService = storageService ?? DefaultServiceContainer.shared.storageService
    }
    
    // MARK: - Computed Properties
    
    var filteredMatches: [SongMatch] {
        if searchText.isEmpty {
            return matches
        } else {
            return matches.filter { match in
                match.title.localizedCaseInsensitiveContains(searchText) ||
                match.artist.localizedCaseInsensitiveContains(searchText) ||
                (match.album?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
    }
    
    var isEmpty: Bool {
        return matches.isEmpty
    }
    
    var hasSearchResults: Bool {
        return !filteredMatches.isEmpty
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
    
    func filterMatches(by criteria: FilterCriteria) -> [SongMatch] {
        var filtered = filteredMatches
        
        // Filter by enrichment status
        switch criteria.enrichmentStatus {
        case .all:
            break
        case .enriched:
            filtered = filtered.filter { $0.enrichmentData != nil }
        case .notEnriched:
            filtered = filtered.filter { $0.enrichmentData == nil }
        }
        
        // Filter by date range
        if let startDate = criteria.startDate {
            filtered = filtered.filter { $0.matchedAt >= startDate }
        }
        
        if let endDate = criteria.endDate {
            filtered = filtered.filter { $0.matchedAt <= endDate }
        }
        
        logWithTimestamp("Applied filters - \(filtered.count) matches remain")
        return filtered
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