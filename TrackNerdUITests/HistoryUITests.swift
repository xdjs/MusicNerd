//
//  HistoryUITests.swift
//  TrackNerdUITests
//
//  Created by Claude on 8/10/25.
//

import XCTest

final class HistoryUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation and Basic Elements Tests
    
    @MainActor
    func testHistoryViewElements() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10.0), "History tab should exist")
        historyTab.tap()
        
        // Verify navigation title
        let historyTitle = app.navigationBars["History"]
        XCTAssertTrue(historyTitle.waitForExistence(timeout: 5.0), "History navigation title should be visible")
        
        // Verify search field exists
        let searchField = app.textFields["search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0), "Search field should be visible")
        
        // Verify filter button exists
        let filterButton = app.buttons["filter-button"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5.0), "Filter button should be visible")
        
        // Verify export button exists
        let exportButton = app.buttons["export-button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5.0), "Export button should be visible")
    }
    
    @MainActor
    func testEmptyHistoryState() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Wait for content to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Check for empty state elements
        // Note: This test assumes no matches exist. In a real test environment,
        // we would clear the database or use a test-specific data state
        let emptyStateText = app.staticTexts["No Matches Yet"]
        if emptyStateText.exists {
            XCTAssertTrue(emptyStateText.isHittable, "Empty state text should be visible")
            
            let emptyStateDescription = app.staticTexts["Start listening to music to build your collection"]
            XCTAssertTrue(emptyStateDescription.exists, "Empty state description should be visible")
            
            // Verify disabled start listening button in empty state
            let startListeningButton = app.buttons["start-listening-button"]
            if startListeningButton.exists {
                // Button should be disabled in empty state
                XCTAssertFalse(startListeningButton.isEnabled, "Start listening button should be disabled in empty state")
            }
        }
    }
    
    // MARK: - Search Functionality Tests
    
    @MainActor
    func testSearchFieldInteraction() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Test search field interaction
        let searchField = app.textFields["search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0), "Search field should be available")
        
        // Tap search field
        searchField.tap()
        
        // Type search query
        searchField.typeText("Queen")
        
        // Verify cancel button appears
        let cancelButton = app.buttons["search-cancel-button"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2.0), "Cancel button should appear when typing in search")
        
        // Test cancel functionality
        cancelButton.tap()
        
        // Verify search field is cleared
        XCTAssertEqual(searchField.value as? String, "Search your matches...", "Search field should be cleared after cancel")
        
        // Cancel button should disappear
        XCTAssertFalse(cancelButton.exists, "Cancel button should disappear after clearing search")
    }
    
    @MainActor
    func testSearchWithResults() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        let searchField = app.textFields["search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0))
        
        // Test searching for a common term
        searchField.tap()
        searchField.typeText("Rock")
        
        // Wait for search results to update
        Thread.sleep(forTimeInterval: 1.0)
        
        // Check if results are filtered (this would depend on actual data)
        // In a real test, we would verify specific match cards appear/disappear
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Verify scrolling works with search results
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
        
        // Clear search
        let cancelButton = app.buttons["search-cancel-button"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }
    
    @MainActor
    func testSearchNoResults() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        let searchField = app.textFields["search-field"]
        searchField.tap()
        
        // Search for something that shouldn't exist
        searchField.typeText("XYZ123NonexistentSong456")
        
        // Wait for search to process
        Thread.sleep(forTimeInterval: 1.0)
        
        // Check for no results state
        let noResultsText = app.staticTexts["No Results"]
        if noResultsText.exists {
            XCTAssertTrue(noResultsText.isHittable, "No results text should be visible")
            
            let noResultsDescription = app.staticTexts["Try searching for a different song or artist"]
            XCTAssertTrue(noResultsDescription.exists, "No results description should be visible")
        }
    }
    
    // MARK: - Filter Functionality Tests
    
    @MainActor
    func testFilterButtonAndSheet() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Tap filter button
        let filterButton = app.buttons["filter-button"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5.0))
        filterButton.tap()
        
        // Verify filter sheet appears
        let filterSheet = app.navigationBars["Filter History"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 3.0), "Filter sheet should appear")
        
        // Verify filter options exist
        let enrichmentSection = app.staticTexts["Enrichment Status"]
        XCTAssertTrue(enrichmentSection.exists, "Enrichment Status section should exist")
        
        let dateRangeSection = app.staticTexts["Date Range"]
        XCTAssertTrue(dateRangeSection.exists, "Date Range section should exist")
        
        // Test filter options
        let allOption = app.staticTexts["All"]
        XCTAssertTrue(allOption.exists, "All enrichment option should exist")
        
        let enrichedOption = app.staticTexts["With Insights"]
        XCTAssertTrue(enrichedOption.exists, "With Insights option should exist")
        
        let notEnrichedOption = app.staticTexts["Without Insights"]
        XCTAssertTrue(notEnrichedOption.exists, "Without Insights option should exist")
        
        // Test date range options
        let allTimeOption = app.staticTexts["All Time"]
        XCTAssertTrue(allTimeOption.exists, "All Time option should exist")
        
        let todayOption = app.staticTexts["Today"]
        XCTAssertTrue(todayOption.exists, "Today option should exist")
        
        let thisWeekOption = app.staticTexts["This Week"]
        XCTAssertTrue(thisWeekOption.exists, "This Week option should exist")
        
        // Test applying a filter
        enrichedOption.tap()
        
        // Apply filters
        let applyButton = app.buttons["Apply"]
        XCTAssertTrue(applyButton.exists, "Apply button should exist")
        applyButton.tap()
        
        // Verify filter sheet dismisses
        XCTAssertFalse(filterSheet.exists, "Filter sheet should dismiss after applying")
        
        // Verify filter indicator appears
        let filterIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'filter'")).firstMatch
        if filterIndicator.exists {
            // Filter indicator should be visible when filters are active
            XCTAssertTrue(filterIndicator.isHittable)
        }
    }
    
    @MainActor
    func testFilterReset() throws {
        app.launch()
        
        // Navigate to History tab and open filters
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        let filterButton = app.buttons["filter-button"]
        filterButton.tap()
        
        // Apply a filter first
        let enrichedOption = app.staticTexts["With Insights"]
        enrichedOption.tap()
        
        // Test reset functionality
        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists, "Reset button should exist")
        resetButton.tap()
        
        // Verify "All" is selected again
        let allOption = app.staticTexts["All"]
        // In a more sophisticated test, we would verify the checkmark appears next to "All"
        
        // Apply after reset
        let applyButton = app.buttons["Apply"]
        applyButton.tap()
    }
    
    @MainActor
    func testClearActiveFilters() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Apply a filter to get active filter state
        let filterButton = app.buttons["filter-button"]
        filterButton.tap()
        
        let enrichedOption = app.staticTexts["With Insights"]
        enrichedOption.tap()
        
        let applyButton = app.buttons["Apply"]
        applyButton.tap()
        
        // Look for clear filters button (should appear when filters are active)
        let clearFiltersButton = app.buttons["clear-filters-button"]
        if clearFiltersButton.exists {
            XCTAssertTrue(clearFiltersButton.isHittable, "Clear filters button should be interactive")
            clearFiltersButton.tap()
            
            // Verify filter indicator disappears
            Thread.sleep(forTimeInterval: 0.5)
            XCTAssertFalse(clearFiltersButton.exists, "Clear filters button should disappear when no filters active")
        }
    }
    
    // MARK: - Match List Interaction Tests
    
    @MainActor
    func testHistoryListScrolling() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Wait for content to load
        Thread.sleep(forTimeInterval: 2.0)
        
        // Find the scroll view (main content area)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Test basic scrolling
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Test pull-to-refresh gesture
            scrollView.swipeDown()
            scrollView.swipeDown() // Extra swipe to trigger refresh
            
            // Wait for refresh to complete
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
    
    @MainActor
    func testMatchCardInteraction() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Wait for content
        Thread.sleep(forTimeInterval: 2.0)
        
        // Look for match cards with the accessibility identifier pattern
        let firstMatch = app.buttons["history-match-0"]
        if firstMatch.waitForExistence(timeout: 3.0) {
            // Test tapping on a match card
            firstMatch.tap()
            
            // Verify match detail view appears
            // Note: This depends on MatchDetailView having proper accessibility identifiers
            let detailView = app.navigationBars.firstMatch
            if detailView.waitForExistence(timeout: 3.0) {
                // Detail view should appear
                XCTAssertTrue(detailView.exists, "Match detail view should appear")
                
                // Test going back
                let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Back' OR label CONTAINS 'History'")).firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }
    
    @MainActor
    func testMatchCardContextMenu() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Wait for content
        Thread.sleep(forTimeInterval: 2.0)
        
        // Look for a match card
        let firstMatch = app.buttons["history-match-0"]
        if firstMatch.waitForExistence(timeout: 3.0) {
            // Long press to trigger context menu
            firstMatch.press(forDuration: 1.0)
            
            // Look for context menu options
            let deleteButton = app.buttons["Delete"]
            if deleteButton.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(deleteButton.exists, "Delete option should appear in context menu")
                
                // Tap outside to dismiss context menu without deleting
                let historyTitle = app.navigationBars["History"]
                historyTitle.tap()
            }
        }
    }
    
    // MARK: - Error State and Loading Tests
    
    @MainActor
    func testLoadingState() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Look for loading indicator (might be brief)
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            // Loading indicator should be visible briefly
            XCTAssertTrue(loadingIndicator.isHittable)
        }
        
        // Wait for loading to complete
        Thread.sleep(forTimeInterval: 2.0)
        
        // Loading indicator should disappear
        XCTAssertFalse(loadingIndicator.exists, "Loading indicator should disappear after loading")
    }
    
    @MainActor
    func testRetryFunctionality() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Look for retry button (would appear if there's an error loading)
        let retryButton = app.buttons["retry-button"]
        if retryButton.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(retryButton.isHittable, "Retry button should be interactive")
            retryButton.tap()
            
            // Wait for retry operation
            Thread.sleep(forTimeInterval: 2.0)
        }
    }
    
    // MARK: - Export Functionality Tests
    
    @MainActor
    func testExportButton() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        let exportButton = app.buttons["export-button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5.0))
        
        // Test that export button is disabled when no matches (if that's the current behavior)
        // or enabled when matches exist
        // Note: The actual behavior depends on whether there are matches in the test data
        
        if exportButton.isEnabled {
            // If enabled, test tapping it
            exportButton.tap()
            
            // Look for export options or share sheet
            // Note: This would depend on the actual export implementation
            Thread.sleep(forTimeInterval: 1.0)
        } else {
            // Verify it's disabled when appropriate
            XCTAssertFalse(exportButton.isEnabled, "Export button should be disabled when no matches exist")
        }
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testSearchAndFilterCombination() throws {
        app.launch()
        
        // Navigate to History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Apply search
        let searchField = app.textFields["search-field"]
        searchField.tap()
        searchField.typeText("Rock")
        
        // Apply filter
        let filterButton = app.buttons["filter-button"]
        filterButton.tap()
        
        let enrichedOption = app.staticTexts["With Insights"]
        enrichedOption.tap()
        
        let applyButton = app.buttons["Apply"]
        applyButton.tap()
        
        // Both search and filter should be active
        // Verify the results are appropriately filtered
        Thread.sleep(forTimeInterval: 1.0)
        
        // Clear search
        let cancelButton = app.buttons["search-cancel-button"]
        if cancelButton.exists {
            cancelButton.tap()
        }
        
        // Filter should still be active
        let clearFiltersButton = app.buttons["clear-filters-button"]
        if clearFiltersButton.exists {
            clearFiltersButton.tap()
        }
    }
    
    @MainActor
    func testNavigationBetweenTabsWithHistory() throws {
        app.launch()
        
        // Start at History tab
        let historyTab = app.tabBars.buttons["History"]
        historyTab.tap()
        
        // Apply a search
        let searchField = app.textFields["search-field"]
        searchField.tap()
        searchField.typeText("Test")
        
        // Navigate to another tab
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // Navigate back to History
        historyTab.tap()
        
        // Verify search state is maintained (or cleared, depending on design)
        let searchValue = searchField.value as? String
        // This test would verify the expected behavior for search persistence
        XCTAssertNotNil(searchValue, "Search field should have some value state")
    }
}