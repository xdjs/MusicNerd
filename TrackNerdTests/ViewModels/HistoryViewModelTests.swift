//
//  HistoryViewModelTests.swift
//  TrackNerdTests
//
//  Created by Claude on 8/10/25.
//

import XCTest
@testable import TrackNerd

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var viewModel: HistoryViewModel!
    var mockStorageService: MockStorageService!
    
    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        viewModel = HistoryViewModel(storageService: mockStorageService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockStorageService = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.matches.isEmpty)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.filterCriteria.enrichmentStatus, .all)
        XCTAssertNil(viewModel.filterCriteria.startDate)
        XCTAssertNil(viewModel.filterCriteria.endDate)
        XCTAssertFalse(viewModel.showingFilter)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(viewModel.hasSearchResults)
        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.activeFilterCount, 0)
    }
    
    // MARK: - Load Matches Tests
    
    func testLoadMatches_Success() async {
        // Given
        let expectedMatches = createTestMatches()
        mockStorageService.mockLoadResult = .success(expectedMatches)
        
        // When
        await viewModel.loadMatches()
        
        // Then
        XCTAssertEqual(viewModel.matches.count, expectedMatches.count)
        XCTAssertEqual(viewModel.matches[0].title, "Bohemian Rhapsody")
        XCTAssertEqual(viewModel.matches[1].title, "Hotel California")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertTrue(viewModel.hasSearchResults)
    }
    
    func testLoadMatches_Failure() async {
        // Given
        mockStorageService.mockLoadResult = .failure(.storageError(.loadFailed))
        
        // When
        await viewModel.loadMatches()
        
        // Then
        XCTAssertTrue(viewModel.matches.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(viewModel.hasSearchResults)
    }
    
    func testRefreshMatches() async {
        // Given
        let expectedMatches = createTestMatches()
        mockStorageService.mockLoadResult = .success(expectedMatches)
        
        // When
        await viewModel.refreshMatches()
        
        // Then
        XCTAssertEqual(viewModel.matches.count, expectedMatches.count)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Search Tests
    
    func testSearchMatches_ByTitle() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.searchMatches(with: "Bohemian")
        
        // Then
        XCTAssertEqual(viewModel.searchText, "Bohemian")
        XCTAssertEqual(viewModel.filteredMatches.count, 1)
        XCTAssertEqual(viewModel.filteredMatches[0].title, "Bohemian Rhapsody")
    }
    
    func testSearchMatches_ByArtist() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.searchMatches(with: "Queen")
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 1)
        XCTAssertEqual(viewModel.filteredMatches[0].artist, "Queen")
    }
    
    func testSearchMatches_ByAlbum() async {
        // Given
        let matches = createTestMatchesWithAlbums()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.searchMatches(with: "Night at the Opera")
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 1)
        XCTAssertEqual(viewModel.filteredMatches[0].album, "A Night at the Opera")
    }
    
    func testSearchMatches_CaseInsensitive() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.searchMatches(with: "QUEEN")
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 1)
        XCTAssertEqual(viewModel.filteredMatches[0].artist, "Queen")
    }
    
    func testSearchMatches_NoResults() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.searchMatches(with: "NonexistentSong")
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 0)
        XCTAssertFalse(viewModel.hasSearchResults)
    }
    
    func testClearSearch() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        viewModel.searchMatches(with: "Queen")
        
        // When
        viewModel.clearSearch()
        
        // Then
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertEqual(viewModel.filteredMatches.count, matches.count)
    }
    
    // MARK: - Filter Tests
    
    func testFilterByEnrichmentStatus_All() async {
        // Given
        let matches = createTestMatchesWithMixedEnrichment()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.filterCriteria.enrichmentStatus = .all
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 3)
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    func testFilterByEnrichmentStatus_Enriched() async {
        // Given
        let matches = createTestMatchesWithMixedEnrichment()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.filterCriteria.enrichmentStatus = .enriched
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 2)
        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.activeFilterCount, 1)
        // Verify all filtered matches have enrichment data
        for match in viewModel.filteredMatches {
            XCTAssertNotNil(match.enrichmentData)
        }
    }
    
    func testFilterByEnrichmentStatus_NotEnriched() async {
        // Given
        let matches = createTestMatchesWithMixedEnrichment()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.filterCriteria.enrichmentStatus = .notEnriched
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 1)
        XCTAssertTrue(viewModel.hasActiveFilters)
        // Verify filtered match has no enrichment data
        XCTAssertNil(viewModel.filteredMatches[0].enrichmentData)
    }
    
    func testFilterByDateRange_StartDate() async {
        // Given
        let matches = createTestMatchesWithDifferentDates()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        let startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        // When
        viewModel.filterCriteria.startDate = startDate
        
        // Then
        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.activeFilterCount, 1)
        // Verify all matches are after start date
        for match in viewModel.filteredMatches {
            XCTAssertTrue(match.matchedAt >= startDate)
        }
    }
    
    func testFilterByDateRange_EndDate() async {
        // Given
        let matches = createTestMatchesWithDifferentDates()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        let endDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        // When
        viewModel.filterCriteria.endDate = endDate
        
        // Then
        XCTAssertTrue(viewModel.hasActiveFilters)
        // Verify all matches are before end date
        for match in viewModel.filteredMatches {
            XCTAssertTrue(match.matchedAt <= endDate)
        }
    }
    
    func testFilterByDateRange_StartAndEndDate() async {
        // Given
        let matches = createTestMatchesWithDifferentDates()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        // When
        viewModel.filterCriteria.startDate = startDate
        viewModel.filterCriteria.endDate = endDate
        
        // Then
        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.activeFilterCount, 1) // Date range counts as 1 filter
        // Verify all matches are within date range
        for match in viewModel.filteredMatches {
            XCTAssertTrue(match.matchedAt >= startDate)
            XCTAssertTrue(match.matchedAt <= endDate)
        }
    }
    
    func testCombinedSearchAndFilter() async {
        // Given
        let matches = createTestMatchesWithMixedEnrichment()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        // When
        viewModel.searchMatches(with: "Hotel")
        viewModel.filterCriteria.enrichmentStatus = .enriched
        
        // Then
        XCTAssertEqual(viewModel.filteredMatches.count, 1)
        XCTAssertEqual(viewModel.filteredMatches[0].title, "Hotel California")
        XCTAssertNotNil(viewModel.filteredMatches[0].enrichmentData)
    }
    
    func testClearFilters() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        await viewModel.loadMatches()
        
        viewModel.filterCriteria.enrichmentStatus = .enriched
        viewModel.filterCriteria.startDate = Date()
        
        // When
        viewModel.clearFilters()
        
        // Then
        XCTAssertEqual(viewModel.filterCriteria.enrichmentStatus, .all)
        XCTAssertNil(viewModel.filterCriteria.startDate)
        XCTAssertNil(viewModel.filterCriteria.endDate)
        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.activeFilterCount, 0)
    }
    
    // MARK: - Delete Match Tests
    
    func testDeleteMatch_Success() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        mockStorageService.mockDeleteResult = .success(())
        await viewModel.loadMatches()
        
        let matchToDelete = viewModel.matches[0]
        let initialCount = viewModel.matches.count
        
        // When
        await viewModel.deleteMatch(matchToDelete)
        
        // Then
        XCTAssertEqual(viewModel.matches.count, initialCount - 1)
        XCTAssertFalse(viewModel.matches.contains { $0.id == matchToDelete.id })
    }
    
    func testDeleteMatch_Failure() async {
        // Given
        let matches = createTestMatches()
        mockStorageService.mockLoadResult = .success(matches)
        mockStorageService.mockDeleteResult = .failure(.storageError(.deleteFailed))
        await viewModel.loadMatches()
        
        let matchToDelete = viewModel.matches[0]
        let initialCount = viewModel.matches.count
        
        // When
        await viewModel.deleteMatch(matchToDelete)
        
        // Then
        XCTAssertEqual(viewModel.matches.count, initialCount) // Count unchanged
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Helper Methods
    
    private func createTestMatches() -> [SongMatch] {
        return [
            SongMatch(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                enrichmentData: EnrichmentData(artistBio: "British rock band")
            ),
            SongMatch(
                title: "Hotel California", 
                artist: "Eagles",
                enrichmentData: EnrichmentData(artistBio: "American rock band")
            ),
            SongMatch(
                title: "Stairway to Heaven",
                artist: "Led Zeppelin"
            )
        ]
    }
    
    private func createTestMatchesWithAlbums() -> [SongMatch] {
        return [
            SongMatch(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                enrichmentData: EnrichmentData(artistBio: "British rock band")
            ),
            SongMatch(
                title: "Hotel California", 
                artist: "Eagles",
                album: "Hotel California"
            )
        ]
    }
    
    private func createTestMatchesWithMixedEnrichment() -> [SongMatch] {
        return [
            SongMatch(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                enrichmentData: EnrichmentData(artistBio: "British rock band")
            ),
            SongMatch(
                title: "Hotel California", 
                artist: "Eagles",
                enrichmentData: EnrichmentData(artistBio: "American rock band")
            ),
            SongMatch(
                title: "Stairway to Heaven",
                artist: "Led Zeppelin"
                // No enrichment data
            )
        ]
    }
    
    private func createTestMatchesWithDifferentDates() -> [SongMatch] {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: now)!
        
        var matches: [SongMatch] = []
        
        let match1 = SongMatch(title: "Recent Song", artist: "Artist 1")
        match1.matchedAt = now
        matches.append(match1)
        
        let match2 = SongMatch(title: "Yesterday Song", artist: "Artist 2")
        match2.matchedAt = yesterday
        matches.append(match2)
        
        let match3 = SongMatch(title: "Two Days Ago", artist: "Artist 3")
        match3.matchedAt = twoDaysAgo
        matches.append(match3)
        
        let match4 = SongMatch(title: "Three Days Ago", artist: "Artist 4")
        match4.matchedAt = threeDaysAgo
        matches.append(match4)
        
        let match5 = SongMatch(title: "Four Days Ago", artist: "Artist 5")
        match5.matchedAt = fourDaysAgo
        matches.append(match5)
        
        return matches
    }
}

// MARK: - Mock Storage Service

class MockStorageService: StorageServiceProtocol {
    var mockLoadResult: Result<[SongMatch]> = .success([])
    var mockSaveResult: Result<Void> = .success(())
    var mockDeleteResult: Result<Void> = .success(())
    
    func save(_ match: SongMatch) async -> Result<Void> {
        return mockSaveResult
    }
    
    func loadMatches() async -> Result<[SongMatch]> {
        return mockLoadResult
    }
    
    func delete(_ match: SongMatch) async -> Result<Void> {
        return mockDeleteResult
    }
}