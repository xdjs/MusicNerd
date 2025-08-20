//
//  FilterCriteriaTests.swift
//  TrackNerdTests
//
//  Created by Claude on 8/10/25.
//

import XCTest
@testable import MusicNerd

final class FilterCriteriaTests: XCTestCase {
    
    // MARK: - FilterCriteria Tests
    
    func testFilterCriteria_InitialState() {
        // Given/When
        let criteria = FilterCriteria()
        
        // Then
        XCTAssertEqual(criteria.enrichmentStatus, .all)
        XCTAssertNil(criteria.startDate)
        XCTAssertNil(criteria.endDate)
        XCTAssertFalse(criteria.isActive)
    }
    
    func testFilterCriteria_IsActive_EnrichmentStatusOnly() {
        // Given
        var criteria = FilterCriteria()
        
        // When
        criteria.enrichmentStatus = .enriched
        
        // Then
        XCTAssertTrue(criteria.isActive)
    }
    
    func testFilterCriteria_IsActive_StartDateOnly() {
        // Given
        var criteria = FilterCriteria()
        
        // When
        criteria.startDate = Date()
        
        // Then
        XCTAssertTrue(criteria.isActive)
    }
    
    func testFilterCriteria_IsActive_EndDateOnly() {
        // Given
        var criteria = FilterCriteria()
        
        // When
        criteria.endDate = Date()
        
        // Then
        XCTAssertTrue(criteria.isActive)
    }
    
    func testFilterCriteria_IsActive_MultipleCriteria() {
        // Given
        var criteria = FilterCriteria()
        
        // When
        criteria.enrichmentStatus = .notEnriched
        criteria.startDate = Date()
        criteria.endDate = Date()
        
        // Then
        XCTAssertTrue(criteria.isActive)
    }
    
    func testFilterCriteria_IsNotActive_AllDefault() {
        // Given
        var criteria = FilterCriteria()
        
        // When
        criteria.enrichmentStatus = .all
        criteria.startDate = nil
        criteria.endDate = nil
        
        // Then
        XCTAssertFalse(criteria.isActive)
    }
    
    // MARK: - EnrichmentStatusFilter Tests
    
    func testEnrichmentStatusFilter_AllCases() {
        // Given/When
        let allCases = EnrichmentStatusFilter.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.enriched))
        XCTAssertTrue(allCases.contains(.notEnriched))
    }
    
    func testEnrichmentStatusFilter_RawValues() {
        // Given/When/Then
        XCTAssertEqual(EnrichmentStatusFilter.all.rawValue, "All")
        XCTAssertEqual(EnrichmentStatusFilter.enriched.rawValue, "With Insights")
        XCTAssertEqual(EnrichmentStatusFilter.notEnriched.rawValue, "Without Insights")
    }
    
    // MARK: - QuickDateFilter Tests
    
    func testQuickDateFilter_AllCases() {
        // Given/When
        let allCases = QuickDateFilter.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.today))
        XCTAssertTrue(allCases.contains(.thisWeek))
        XCTAssertTrue(allCases.contains(.thisMonth))
        XCTAssertTrue(allCases.contains(.last7Days))
        XCTAssertTrue(allCases.contains(.last30Days))
    }
    
    func testQuickDateFilter_DisplayNames() {
        // Given/When/Then
        XCTAssertEqual(QuickDateFilter.all.displayName, "All Time")
        XCTAssertEqual(QuickDateFilter.today.displayName, "Today")
        XCTAssertEqual(QuickDateFilter.thisWeek.displayName, "This Week")
        XCTAssertEqual(QuickDateFilter.thisMonth.displayName, "This Month")
        XCTAssertEqual(QuickDateFilter.last7Days.displayName, "Last 7 Days")
        XCTAssertEqual(QuickDateFilter.last30Days.displayName, "Last 30 Days")
    }
    
    func testQuickDateFilter_AllTime_DateRange() {
        // Given/When
        let (start, end) = QuickDateFilter.all.dateRange
        
        // Then
        XCTAssertNil(start)
        XCTAssertNil(end)
    }
    
    func testQuickDateFilter_Today_DateRange() {
        // Given/When
        let (start, end) = QuickDateFilter.today.dateRange
        let calendar = Calendar.current
        let now = Date()
        
        // Then
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
        
        // Start should be beginning of today
        XCTAssertTrue(calendar.isDate(start!, inSameDayAs: now))
        XCTAssertEqual(calendar.component(.hour, from: start!), 0)
        XCTAssertEqual(calendar.component(.minute, from: start!), 0)
        
        // End should be beginning of tomorrow
        if let end = end {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
            XCTAssertEqual(calendar.compare(end, to: tomorrow, toGranularity: .second), .orderedSame)
        }
    }
    
    func testQuickDateFilter_ThisWeek_DateRange() {
        // Given/When
        let (start, end) = QuickDateFilter.thisWeek.dateRange
        let calendar = Calendar.current
        let now = Date()
        
        // Then
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
        
        // Should be within current week
        let currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: now)!
        XCTAssertEqual(start, currentWeekInterval.start)
        XCTAssertEqual(end, currentWeekInterval.end)
    }
    
    func testQuickDateFilter_ThisMonth_DateRange() {
        // Given/When
        let (start, end) = QuickDateFilter.thisMonth.dateRange
        let calendar = Calendar.current
        let now = Date()
        
        // Then
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
        
        // Should be within current month
        let currentMonthInterval = calendar.dateInterval(of: .month, for: now)!
        XCTAssertEqual(start, currentMonthInterval.start)
        XCTAssertEqual(end, currentMonthInterval.end)
    }
    
    func testQuickDateFilter_Last7Days_DateRange() {
        // Given/When
        let (start, end) = QuickDateFilter.last7Days.dateRange
        let calendar = Calendar.current
        
        // Then
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
        
        // Check that the time difference is approximately 7 days
        if let start = start, let end = end {
            let daysDifference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            XCTAssertEqual(daysDifference, 7, "Last 7 days should span exactly 7 days")
            
            // Verify end is close to now (within a few seconds)
            let now = Date()
            let timeDifference = abs(end.timeIntervalSince(now))
            XCTAssertLessThan(timeDifference, 5.0, "End date should be close to current time")
        }
    }
    
    func testQuickDateFilter_Last30Days_DateRange() {
        // Given/When
        let (start, end) = QuickDateFilter.last30Days.dateRange
        let calendar = Calendar.current
        
        // Then
        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
        
        // Check that the time difference is approximately 30 days
        if let start = start, let end = end {
            let daysDifference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            XCTAssertEqual(daysDifference, 30, "Last 30 days should span exactly 30 days")
            
            // Verify end is close to now (within a few seconds)
            let now = Date()
            let timeDifference = abs(end.timeIntervalSince(now))
            XCTAssertLessThan(timeDifference, 5.0, "End date should be close to current time")
        }
    }
    
    func testQuickDateFilter_DateRange_LogicalOrder() {
        // Test that start date is always before end date for all filters except .all
        let filtersWithDates: [QuickDateFilter] = [.today, .thisWeek, .thisMonth, .last7Days, .last30Days]
        
        for filter in filtersWithDates {
            let (start, end) = filter.dateRange
            
            if let start = start, let end = end {
                XCTAssertTrue(start <= end, "Start date should be before or equal to end date for \(filter.displayName)")
            }
        }
    }
    
    func testQuickDateFilter_DateRange_ReasonableDurations() {
        // Test that date ranges make sense
        let calendar = Calendar.current
        
        // Today should be less than 24 hours
        let (todayStart, todayEnd) = QuickDateFilter.today.dateRange
        if let start = todayStart, let end = todayEnd {
            let duration = end.timeIntervalSince(start)
            XCTAssertLessThanOrEqual(duration, 24 * 60 * 60, "Today should be at most 24 hours")
        }
        
        // Last 7 days should be approximately 7 days
        let (last7Start, last7End) = QuickDateFilter.last7Days.dateRange
        if let start = last7Start, let end = last7End {
            let daysDifference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            XCTAssertEqual(daysDifference, 7, "Last 7 days should span exactly 7 days")
        }
        
        // Last 30 days should be approximately 30 days
        let (last30Start, last30End) = QuickDateFilter.last30Days.dateRange
        if let start = last30Start, let end = last30End {
            let daysDifference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            XCTAssertEqual(daysDifference, 30, "Last 30 days should span exactly 30 days")
        }
    }
}
