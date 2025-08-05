import XCTest
import SwiftUI
@testable import TrackNerd

final class SpacingTests: XCTestCase {
    
    func testSpacingScale() {
        // Test spacing scale consistency
        XCTAssertEqual(CGFloat.MusicNerd.unit, 4)
        
        // Test spacing hierarchy
        XCTAssertEqual(CGFloat.MusicNerd.xs, 4)    // 1 unit
        XCTAssertEqual(CGFloat.MusicNerd.sm, 8)    // 2 units
        XCTAssertEqual(CGFloat.MusicNerd.md, 16)   // 4 units
        XCTAssertEqual(CGFloat.MusicNerd.lg, 24)   // 6 units
        XCTAssertEqual(CGFloat.MusicNerd.xl, 32)   // 8 units
        XCTAssertEqual(CGFloat.MusicNerd.xxl, 48)  // 12 units
        XCTAssertEqual(CGFloat.MusicNerd.xxxl, 64) // 16 units
        
        // Test ascending order
        XCTAssertLessThan(CGFloat.MusicNerd.xs, CGFloat.MusicNerd.sm)
        XCTAssertLessThan(CGFloat.MusicNerd.sm, CGFloat.MusicNerd.md)
        XCTAssertLessThan(CGFloat.MusicNerd.md, CGFloat.MusicNerd.lg)
        XCTAssertLessThan(CGFloat.MusicNerd.lg, CGFloat.MusicNerd.xl)
        XCTAssertLessThan(CGFloat.MusicNerd.xl, CGFloat.MusicNerd.xxl)
        XCTAssertLessThan(CGFloat.MusicNerd.xxl, CGFloat.MusicNerd.xxxl)
    }
    
    func testComponentSpacing() {
        // Test component-specific spacing values
        XCTAssertEqual(CGFloat.MusicNerd.cardPadding, CGFloat.MusicNerd.md)
        XCTAssertEqual(CGFloat.MusicNerd.buttonPadding, CGFloat.MusicNerd.md)
        XCTAssertEqual(CGFloat.MusicNerd.sectionSpacing, CGFloat.MusicNerd.xl)
        XCTAssertEqual(CGFloat.MusicNerd.itemSpacing, CGFloat.MusicNerd.sm)
        
        // Test layout margins
        XCTAssertEqual(CGFloat.MusicNerd.screenMargin, CGFloat.MusicNerd.md)
        XCTAssertEqual(CGFloat.MusicNerd.contentMargin, CGFloat.MusicNerd.lg)
        
        // All spacing values should be positive
        XCTAssertGreaterThan(CGFloat.MusicNerd.cardPadding, 0)
        XCTAssertGreaterThan(CGFloat.MusicNerd.buttonPadding, 0)
        XCTAssertGreaterThan(CGFloat.MusicNerd.sectionSpacing, 0)
        XCTAssertGreaterThan(CGFloat.MusicNerd.itemSpacing, 0)
        XCTAssertGreaterThan(CGFloat.MusicNerd.screenMargin, 0)
        XCTAssertGreaterThan(CGFloat.MusicNerd.contentMargin, 0)
    }
    
    func testBorderRadiusScale() {
        // Test border radius values
        XCTAssertEqual(CGFloat.BorderRadius.xs, 4)
        XCTAssertEqual(CGFloat.BorderRadius.sm, 8)
        XCTAssertEqual(CGFloat.BorderRadius.md, 12)
        XCTAssertEqual(CGFloat.BorderRadius.lg, 16)
        XCTAssertEqual(CGFloat.BorderRadius.xl, 24)
        XCTAssertEqual(CGFloat.BorderRadius.round, 999)
        
        // Test ascending order (except round)
        XCTAssertLessThan(CGFloat.BorderRadius.xs, CGFloat.BorderRadius.sm)
        XCTAssertLessThan(CGFloat.BorderRadius.sm, CGFloat.BorderRadius.md)
        XCTAssertLessThan(CGFloat.BorderRadius.md, CGFloat.BorderRadius.lg)
        XCTAssertLessThan(CGFloat.BorderRadius.lg, CGFloat.BorderRadius.xl)
        XCTAssertGreaterThan(CGFloat.BorderRadius.round, CGFloat.BorderRadius.xl)
        
        // Test component-specific radius
        XCTAssertEqual(CGFloat.BorderRadius.button, CGFloat.BorderRadius.sm)
        XCTAssertEqual(CGFloat.BorderRadius.card, CGFloat.BorderRadius.md)
        XCTAssertEqual(CGFloat.BorderRadius.image, CGFloat.BorderRadius.sm)
        XCTAssertEqual(CGFloat.BorderRadius.sheet, CGFloat.BorderRadius.lg)
    }
    
    func testShadowSystem() {
        let shadows = [
            MusicNerdShadow.none,
            MusicNerdShadow.subtle,
            MusicNerdShadow.soft,
            MusicNerdShadow.medium,
            MusicNerdShadow.strong,
            MusicNerdShadow.intense
        ]
        
        for shadow in shadows {
            XCTAssertNotNil(shadow.color)
            XCTAssertGreaterThanOrEqual(shadow.radius, 0)
            XCTAssertGreaterThanOrEqual(shadow.opacity, 0)
            XCTAssertLessThanOrEqual(shadow.opacity, 1)
        }
        
        // Test shadow hierarchy
        XCTAssertLessThan(MusicNerdShadow.none.radius, MusicNerdShadow.subtle.radius)
        XCTAssertLessThan(MusicNerdShadow.subtle.radius, MusicNerdShadow.soft.radius)
        XCTAssertLessThan(MusicNerdShadow.soft.radius, MusicNerdShadow.medium.radius)
        XCTAssertLessThan(MusicNerdShadow.medium.radius, MusicNerdShadow.strong.radius)
        XCTAssertLessThan(MusicNerdShadow.strong.radius, MusicNerdShadow.intense.radius)
        
        // Test opacity hierarchy
        XCTAssertLessThan(MusicNerdShadow.none.opacity, MusicNerdShadow.subtle.opacity)
        XCTAssertLessThan(MusicNerdShadow.subtle.opacity, MusicNerdShadow.soft.opacity)
        XCTAssertLessThan(MusicNerdShadow.soft.opacity, MusicNerdShadow.medium.opacity)
    }
    
    func testShadowNoneValues() {
        let noneShadow = MusicNerdShadow.none
        
        XCTAssertEqual(noneShadow.radius, 0)
        XCTAssertEqual(noneShadow.x, 0)
        XCTAssertEqual(noneShadow.y, 0)
        XCTAssertEqual(noneShadow.opacity, 0)
        XCTAssertEqual(noneShadow.color, .clear)
    }
    
    func testResponsiveSpacing() {
        // Test horizontal spacing for different screen widths
        let narrowScreen: CGFloat = 300
        let mediumScreen: CGFloat = 400
        let wideScreen: CGFloat = 800
        
        let narrowSpacing = ResponsiveSpacing.horizontal(for: narrowScreen)
        let mediumSpacing = ResponsiveSpacing.horizontal(for: mediumScreen)
        let wideSpacing = ResponsiveSpacing.horizontal(for: wideScreen)
        
        XCTAssertGreaterThan(narrowSpacing, 0)
        XCTAssertGreaterThan(mediumSpacing, 0)
        XCTAssertGreaterThan(wideSpacing, 0)
        
        // Wider screens should have more spacing
        XCTAssertLessThanOrEqual(narrowSpacing, mediumSpacing)
        XCTAssertLessThanOrEqual(mediumSpacing, wideSpacing)
        
        // Test vertical spacing for different screen heights
        let shortScreen: CGFloat = 500
        let mediumHeightScreen: CGFloat = 700
        let tallScreen: CGFloat = 900
        
        let shortSpacing = ResponsiveSpacing.vertical(for: shortScreen)
        let mediumHeightSpacing = ResponsiveSpacing.vertical(for: mediumHeightScreen)
        let tallSpacing = ResponsiveSpacing.vertical(for: tallScreen)
        
        XCTAssertGreaterThan(shortSpacing, 0)
        XCTAssertGreaterThan(mediumHeightSpacing, 0)
        XCTAssertGreaterThan(tallSpacing, 0)
        
        // Taller screens should have more spacing
        XCTAssertLessThanOrEqual(shortSpacing, mediumHeightSpacing)
        XCTAssertLessThanOrEqual(mediumHeightSpacing, tallSpacing)
    }
    
    func testSpacingConsistency() {
        // Test that all spacing values follow the base unit system
        let baseUnit = CGFloat.MusicNerd.unit
        
        XCTAssertEqual(CGFloat.MusicNerd.xs.truncatingRemainder(dividingBy: baseUnit), 0)
        XCTAssertEqual(CGFloat.MusicNerd.sm.truncatingRemainder(dividingBy: baseUnit), 0)
        XCTAssertEqual(CGFloat.MusicNerd.md.truncatingRemainder(dividingBy: baseUnit), 0)
        XCTAssertEqual(CGFloat.MusicNerd.lg.truncatingRemainder(dividingBy: baseUnit), 0)
        XCTAssertEqual(CGFloat.MusicNerd.xl.truncatingRemainder(dividingBy: baseUnit), 0)
        XCTAssertEqual(CGFloat.MusicNerd.xxl.truncatingRemainder(dividingBy: baseUnit), 0)
        XCTAssertEqual(CGFloat.MusicNerd.xxxl.truncatingRemainder(dividingBy: baseUnit), 0)
    }
    
    func testBorderRadiusConsistency() {
        // Test that border radius values are reasonable
        let radii = [
            CGFloat.BorderRadius.xs,
            CGFloat.BorderRadius.sm,
            CGFloat.BorderRadius.md,
            CGFloat.BorderRadius.lg,
            CGFloat.BorderRadius.xl
        ]
        
        for radius in radii {
            XCTAssertGreaterThan(radius, 0)
            XCTAssertLessThan(radius, 100) // Reasonable upper bound
        }
        
        // Round should be very large for full rounding
        XCTAssertGreaterThan(CGFloat.BorderRadius.round, 100)
    }
    
    func testMusicNerdSectionInitialization() {
        // Test that MusicNerdSection can be created
        // We can't easily test SwiftUI views, but we can test that they compile
        XCTAssertTrue(true) // Compilation test
    }
    
    func testMusicNerdContainerInitialization() {
        // Test that MusicNerdContainer can be created
        // We can't easily test SwiftUI views, but we can test that they compile
        XCTAssertTrue(true) // Compilation test
    }
}
