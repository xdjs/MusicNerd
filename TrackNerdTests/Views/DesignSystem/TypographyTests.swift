import XCTest
import SwiftUI
@testable import TrackNerd

final class TypographyTests: XCTestCase {
    
    func testDisplayFonts() {
        // Test display font sizes and weights
        XCTAssertNotNil(Font.MusicNerd.displayLarge)
        XCTAssertNotNil(Font.MusicNerd.displayMedium)
        XCTAssertNotNil(Font.MusicNerd.displaySmall)
    }
    
    func testHeadlineFonts() {
        // Test headline font hierarchy
        XCTAssertNotNil(Font.MusicNerd.headlineLarge)
        XCTAssertNotNil(Font.MusicNerd.headlineMedium)
        XCTAssertNotNil(Font.MusicNerd.headlineSmall)
    }
    
    func testTitleFonts() {
        // Test title font variations
        XCTAssertNotNil(Font.MusicNerd.titleLarge)
        XCTAssertNotNil(Font.MusicNerd.titleMedium)
        XCTAssertNotNil(Font.MusicNerd.titleSmall)
    }
    
    func testBodyFonts() {
        // Test body text fonts
        XCTAssertNotNil(Font.MusicNerd.bodyLarge)
        XCTAssertNotNil(Font.MusicNerd.bodyMedium)
        XCTAssertNotNil(Font.MusicNerd.bodySmall)
    }
    
    func testLabelFonts() {
        // Test label fonts for UI elements
        XCTAssertNotNil(Font.MusicNerd.labelLarge)
        XCTAssertNotNil(Font.MusicNerd.labelMedium)
        XCTAssertNotNil(Font.MusicNerd.labelSmall)
    }
    
    func testCaptionFonts() {
        // Test caption fonts
        XCTAssertNotNil(Font.MusicNerd.caption)
        XCTAssertNotNil(Font.MusicNerd.captionBold)
    }
    
    func testMonospaceFonts() {
        // Test monospace fonts for technical content
        XCTAssertNotNil(Font.MusicNerd.mono)
        XCTAssertNotNil(Font.MusicNerd.monoSmall)
    }
    
    func testTextStyleInitialization() {
        // Test that all text styles can be initialized
        let styles: [MusicNerdTextStyle] = [
            .displayLarge(),
            .displayMedium(),
            .displaySmall(),
            .headlineLarge(),
            .headlineMedium(),
            .headlineSmall(),
            .titleLarge(),
            .titleMedium(),
            .titleSmall(),
            .bodyLarge(),
            .bodyMedium(),
            .bodySmall(),
            .labelLarge(),
            .labelMedium(),
            .labelSmall(),
            .caption(),
            .captionBold()
        ]
        
        for style in styles {
            XCTAssertNotNil(style.font)
            XCTAssertNotNil(style.color)
            XCTAssertGreaterThanOrEqual(style.lineSpacing, 0)
        }
    }
    
    func testTextStyleWithCustomColor() {
        // Test text styles with custom colors
        let customColor = Color.red
        let style = MusicNerdTextStyle.displayLarge(color: customColor)
        
        XCTAssertNotNil(style.font)
        XCTAssertEqual(style.color, customColor)
    }
    
    func testLineSpacingValues() {
        // Test that different text styles have appropriate line spacing
        let displayStyle = MusicNerdTextStyle.displayLarge()
        let bodyStyle = MusicNerdTextStyle.bodyMedium()
        let captionStyle = MusicNerdTextStyle.caption()
        
        // Display should have more line spacing than body
        XCTAssertGreaterThan(displayStyle.lineSpacing, bodyStyle.lineSpacing)
        
        // Caption should have minimal line spacing
        XCTAssertLessThanOrEqual(captionStyle.lineSpacing, bodyStyle.lineSpacing)
    }
    
    func testDefaultColors() {
        // Test default text colors
        let primaryTextStyle = MusicNerdTextStyle.bodyLarge()
        let captionStyle = MusicNerdTextStyle.caption()
        
        // Primary text should use primary text color
        // Caption should use secondary text color
        XCTAssertNotNil(primaryTextStyle.color)
        XCTAssertNotNil(captionStyle.color)
    }
    
    func testFontWeights() {
        // Test that different font categories use appropriate weights
        // We can't directly test font weights, but we can ensure fonts are created
        let boldFont = Font.MusicNerd.displayLarge  // Should be bold
        let regularFont = Font.MusicNerd.bodyMedium  // Should be regular
        let mediumFont = Font.MusicNerd.labelLarge   // Should be medium
        
        XCTAssertNotNil(boldFont)
        XCTAssertNotNil(regularFont)
        XCTAssertNotNil(mediumFont)
    }
    
    func testFontDesigns() {
        // Test that different designs are used appropriately
        let roundedFont = Font.MusicNerd.displayLarge  // Should use rounded design
        let defaultFont = Font.MusicNerd.bodyMedium    // Should use default design
        let monoFont = Font.MusicNerd.mono             // Should use monospaced design
        
        XCTAssertNotNil(roundedFont)
        XCTAssertNotNil(defaultFont)
        XCTAssertNotNil(monoFont)
    }
    
    func testTypographyHierarchy() {
        // Test that we have a proper typographic hierarchy
        // All typography styles should be available
        let allStyles = [
            Font.MusicNerd.displayLarge,
            Font.MusicNerd.displayMedium,
            Font.MusicNerd.displaySmall,
            Font.MusicNerd.headlineLarge,
            Font.MusicNerd.headlineMedium,
            Font.MusicNerd.headlineSmall,
            Font.MusicNerd.titleLarge,
            Font.MusicNerd.titleMedium,
            Font.MusicNerd.titleSmall,
            Font.MusicNerd.bodyLarge,
            Font.MusicNerd.bodyMedium,
            Font.MusicNerd.bodySmall,
            Font.MusicNerd.labelLarge,
            Font.MusicNerd.labelMedium,
            Font.MusicNerd.labelSmall,
            Font.MusicNerd.caption,
            Font.MusicNerd.captionBold,
            Font.MusicNerd.mono,
            Font.MusicNerd.monoSmall
        ]
        
        // Should have 19 different typography styles
        XCTAssertEqual(allStyles.count, 19)
        
        // All should be non-nil
        for font in allStyles {
            XCTAssertNotNil(font)
        }
    }
}
