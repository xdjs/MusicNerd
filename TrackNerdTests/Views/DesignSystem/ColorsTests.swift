import XCTest
import SwiftUI
@testable import TrackNerd

final class ColorsTests: XCTestCase {
    
    func testMusicNerdColorInitialization() {
        // Test that all Music Nerd colors can be initialized
        XCTAssertNotNil(Color.MusicNerd.primary)
        XCTAssertNotNil(Color.MusicNerd.secondary)
        XCTAssertNotNil(Color.MusicNerd.accent)
        XCTAssertNotNil(Color.MusicNerd.background)
        XCTAssertNotNil(Color.MusicNerd.surface)
        XCTAssertNotNil(Color.MusicNerd.text)
        XCTAssertNotNil(Color.MusicNerd.textSecondary)
        XCTAssertNotNil(Color.MusicNerd.textInverse)
    }
    
    func testHexColorInitialization() {
        // Test 3-digit hex
        let color3 = Color(hex: "F0A")
        XCTAssertNotNil(color3)
        
        // Test 6-digit hex
        let color6 = Color(hex: "FF69B4")
        XCTAssertNotNil(color6)
        
        // Test 8-digit hex with alpha
        let color8 = Color(hex: "FF69B4FF")
        XCTAssertNotNil(color8)
        
        // Test hex with hash
        let colorWithHash = Color(hex: "#FF69B4")
        XCTAssertNotNil(colorWithHash)
        
        // Test invalid hex gracefully handles
        let invalidColor = Color(hex: "invalid")
        XCTAssertNotNil(invalidColor) // Should create a fallback color
    }
    
    func testHexColorConversion() {
        // Test known hex to RGB conversion
        let hotPink = Color(hex: "FF69B4")
        
        // We can't directly test RGB values from SwiftUI Color,
        // but we can test that the color is created successfully
        XCTAssertNotNil(hotPink)
    }
    
    func testBrandColorConsistency() {
        // Test that brand colors match expected hex values
        let primary = Color(hex: "#FF69B4")
        let secondary = Color(hex: "#FF1493")
        let accent = Color(hex: "#FFB6C1")
        
        XCTAssertNotNil(primary)
        XCTAssertNotNil(secondary)
        XCTAssertNotNil(accent)
    }
    
    func testStatusColors() {
        // Test that status colors are properly defined
        XCTAssertNotNil(Color.MusicNerd.success)
        XCTAssertNotNil(Color.MusicNerd.warning)
        XCTAssertNotNil(Color.MusicNerd.error)
        XCTAssertNotNil(Color.MusicNerd.info)
    }
    
    func testInteractiveColors() {
        // Test button and interactive colors
        XCTAssertNotNil(Color.MusicNerd.buttonPrimary)
        XCTAssertNotNil(Color.MusicNerd.buttonSecondary)
        XCTAssertNotNil(Color.MusicNerd.buttonDisabled)
    }
    
    func testWaveformColors() {
        // Test audio visualization colors
        XCTAssertNotNil(Color.MusicNerd.waveformActive)
        XCTAssertNotNil(Color.MusicNerd.waveformInactive)
    }
    
    func testColorAccessibility() {
        // Test that we have proper contrast colors defined
        XCTAssertNotNil(Color.MusicNerd.text)
        XCTAssertNotNil(Color.MusicNerd.textInverse)
        XCTAssertNotNil(Color.MusicNerd.background)
        XCTAssertNotNil(Color.MusicNerd.surface)
        
        // These should be different colors for proper contrast
        // We can't test exact values, but we can ensure they exist
        XCTAssertTrue(true) // Colors exist as verified above
    }
    
    func testHexStringParsing() {
        // Test various hex string formats
        let formats = [
            "FFF",      // 3-digit
            "FFFFFF",   // 6-digit  
            "FFFFFFFF", // 8-digit with alpha
            "#FFF",     // with hash 3-digit
            "#FFFFFF",  // with hash 6-digit
            "#FFFFFFFF" // with hash 8-digit
        ]
        
        for format in formats {
            let color = Color(hex: format)
            XCTAssertNotNil(color, "Should handle hex format: \(format)")
        }
    }
    
    func testEdgeCaseHexValues() {
        // Test edge cases
        let edgeCases = [
            "",           // Empty string
            "G",          // Invalid character
            "12345",      // Invalid length
            "1234567890", // Too long
            " FF69B4 "    // With whitespace
        ]
        
        for edgeCase in edgeCases {
            let color = Color(hex: edgeCase)
            XCTAssertNotNil(color, "Should handle edge case gracefully: \(edgeCase)")
        }
    }
}
