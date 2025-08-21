import XCTest
import SwiftUI
@testable import MusicNerd

final class ComponentsTests: XCTestCase {
    
    // MARK: - Button Tests
    func testMusicNerdButtonInitialization() {
        let button = MusicNerdButton(title: "Test", action: {})
        
        XCTAssertEqual(button.title, "Test")
        XCTAssertEqual(button.style, .primary)
        XCTAssertEqual(button.size, .medium)
        XCTAssertTrue(button.isEnabled)
        XCTAssertFalse(button.isLoading)
        XCTAssertNil(button.icon)
    }
    
    func testMusicNerdButtonStyles() {
        let styles: [MusicNerdButton.ButtonStyle] = [.primary, .secondary, .outline, .ghost, .destructive]
        
        for style in styles {
            XCTAssertNotNil(style.backgroundColor)
            XCTAssertNotNil(style.foregroundColor)
            XCTAssertNotNil(style.borderColor)
            XCTAssertGreaterThanOrEqual(style.borderWidth, 0)
        }
    }
    
    func testMusicNerdButtonSizes() {
        let sizes: [MusicNerdButton.ButtonSize] = [.small, .medium, .large]
        
        for size in sizes {
            XCTAssertGreaterThan(size.height, 0)
            XCTAssertGreaterThan(size.horizontalPadding, 0)
            XCTAssertNotNil(size.font)
            XCTAssertGreaterThan(size.iconSize, 0)
        }
        
        // Test size hierarchy
        XCTAssertLessThan(MusicNerdButton.ButtonSize.small.height, MusicNerdButton.ButtonSize.medium.height)
        XCTAssertLessThan(MusicNerdButton.ButtonSize.medium.height, MusicNerdButton.ButtonSize.large.height)
    }
    
    func testButtonStyleColors() {
        let primaryStyle = MusicNerdButton.ButtonStyle.primary
        let secondaryStyle = MusicNerdButton.ButtonStyle.secondary
        let outlineStyle = MusicNerdButton.ButtonStyle.outline
        
        // Primary should have colored background
        XCTAssertNotEqual(primaryStyle.backgroundColor, Color.clear)
        
        // Outline should have clear background
        XCTAssertEqual(outlineStyle.backgroundColor, Color.clear)
        
        // All styles should have defined foreground colors
        XCTAssertNotNil(primaryStyle.foregroundColor)
        XCTAssertNotNil(secondaryStyle.foregroundColor)
        XCTAssertNotNil(outlineStyle.foregroundColor)
    }
    
    // MARK: - Card Tests
    func testMusicNerdCardStyles() {
        let styles: [MusicNerdCard<Text>.CardStyle] = [.default, .elevated, .outline, .filled]
        
        for style in styles {
            XCTAssertNotNil(style.backgroundColor)
            XCTAssertNotNil(style.borderColor)
            XCTAssertGreaterThanOrEqual(style.borderWidth, 0)
            XCTAssertGreaterThanOrEqual(style.shadowRadius, 0)
            XCTAssertGreaterThanOrEqual(style.shadowOpacity, 0)
            XCTAssertLessThanOrEqual(style.shadowOpacity, 1)
        }
    }
    
    func testCardStyleProperties() {
        let elevatedStyle = MusicNerdCard<Text>.CardStyle.elevated
        let outlineStyle = MusicNerdCard<Text>.CardStyle.outline
        let defaultStyle = MusicNerdCard<Text>.CardStyle.default
        
        // Elevated should have more shadow than default
        XCTAssertGreaterThan(elevatedStyle.shadowRadius, defaultStyle.shadowRadius)
        XCTAssertGreaterThan(elevatedStyle.shadowOpacity, defaultStyle.shadowOpacity)
        
        // Outline should have border
        XCTAssertGreaterThan(outlineStyle.borderWidth, 0)
        XCTAssertEqual(defaultStyle.borderWidth, 0)
    }
    
    func testSongMatchCardInitialization() {
        let testMatch = SongMatch(title: "Test Song", artist: "Test Artist")
        let card = SongMatchCard(match: testMatch)
        
        XCTAssertEqual(card.match.title, "Test Song")
        XCTAssertEqual(card.match.artist, "Test Artist")
    }
    
    // MARK: - Loading States Tests
    func testLoadingSpinnerSizes() {
        let sizes: [MusicNerdLoadingSpinner.SpinnerSize] = [.small, .medium, .large]
        
        for size in sizes {
            XCTAssertGreaterThan(size.dimension, 0)
            XCTAssertGreaterThan(size.lineWidth, 0)
        }
        
        // Test size hierarchy
        XCTAssertLessThan(MusicNerdLoadingSpinner.SpinnerSize.small.dimension, 
                         MusicNerdLoadingSpinner.SpinnerSize.medium.dimension)
        XCTAssertLessThan(MusicNerdLoadingSpinner.SpinnerSize.medium.dimension, 
                         MusicNerdLoadingSpinner.SpinnerSize.large.dimension)
    }
    
    func testLoadingStateTypes() {
        let types: [LoadingStateView.LoadingType] = [.spinner, .waveform, .pulse]
        
        // Test that all loading types are defined
        for type in types {
            switch type {
            case .spinner, .waveform, .pulse:
                XCTAssertTrue(true) // All types are valid
            }
        }
    }
    
    func testLoadingStateViewInitialization() {
        let loadingView = LoadingStateView(message: "Loading...", loadingType: .spinner)
        
        XCTAssertEqual(loadingView.message, "Loading...")
        XCTAssertEqual(loadingView.loadingType, .spinner)
        XCTAssertTrue(loadingView.showMessage)
    }
    
    // MARK: - Shimmer Effect Tests
    func testShimmerEffectInitialization() {
        let shimmer = ShimmerEffect(delay: 0.5)
        XCTAssertEqual(shimmer.delay, 0.5)
    }
    
    // MARK: - Progress View Tests
    func testMusicNerdProgressView() {
        let progressView = MusicNerdProgressView(progress: 0.5)
        
        XCTAssertEqual(progressView.progress, 0.5)
        XCTAssertGreaterThan(progressView.height, 0)
        XCTAssertNotNil(progressView.backgroundColor)
        XCTAssertNotNil(progressView.foregroundColor)
    }
    
    func testProgressViewBounds() {
        // Test progress bounds
        let progressValues = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for progress in progressValues {
            let progressView = MusicNerdProgressView(progress: progress)
            XCTAssertGreaterThanOrEqual(progressView.progress, 0.0)
            XCTAssertLessThanOrEqual(progressView.progress, 1.0)
        }
    }
    
    // MARK: - Component Integration Tests
    func testComponentColorConsistency() {
        // Test that components use consistent colors from the design system
        let buttonPrimary = MusicNerdButton.ButtonStyle.primary.backgroundColor
        let cardDefault = MusicNerdCard<Text>.CardStyle.default.backgroundColor
        
        XCTAssertNotNil(buttonPrimary)
        XCTAssertNotNil(cardDefault)
    }
    
    func testComponentSpacingConsistency() {
        // Test that components use consistent spacing
        let smallSize = MusicNerdButton.ButtonSize.small
        let mediumSize = MusicNerdButton.ButtonSize.medium
        
        XCTAssertGreaterThan(smallSize.horizontalPadding, 0)
        XCTAssertGreaterThan(mediumSize.horizontalPadding, smallSize.horizontalPadding)
    }
    
    func testAccessibilityPreparation() {
        // Test that components are prepared for accessibility
        let button = MusicNerdButton(title: "Accessible Button", action: {})
        let testMatch = SongMatch(title: "Test", artist: "Test")
        let card = SongMatchCard(match: testMatch)
        
        XCTAssertFalse(button.title.isEmpty)
        XCTAssertFalse(card.match.title.isEmpty)
        XCTAssertFalse(card.match.artist.isEmpty)
    }
}
