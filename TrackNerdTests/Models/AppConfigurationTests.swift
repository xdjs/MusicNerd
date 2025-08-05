import XCTest
@testable import TrackNerd

final class AppConfigurationTests: XCTestCase {
    
    func testAPIConfiguration() {
        XCTAssertEqual(AppConfiguration.API.baseURL, "https://api.TrackNerd.com")
        XCTAssertEqual(AppConfiguration.API.enrichEndpoint, "/enrich")
        XCTAssertEqual(AppConfiguration.API.timeoutInterval, 30.0)
        XCTAssertEqual(AppConfiguration.API.maxRetryAttempts, 3)
        XCTAssertEqual(AppConfiguration.API.rateLimitDelay, 1.0)
        
        XCTAssertGreaterThan(AppConfiguration.API.timeoutInterval, 0)
        XCTAssertGreaterThan(AppConfiguration.API.maxRetryAttempts, 0)
    }
    
    func testShazamConfiguration() {
        XCTAssertEqual(AppConfiguration.Shazam.maxRecordingDuration, 15.0)
        XCTAssertEqual(AppConfiguration.Shazam.minRecordingDuration, 3.0)
        XCTAssertEqual(AppConfiguration.Shazam.sampleRate, 44100.0)
        
        XCTAssertGreaterThan(AppConfiguration.Shazam.maxRecordingDuration, AppConfiguration.Shazam.minRecordingDuration)
        XCTAssertGreaterThan(AppConfiguration.Shazam.sampleRate, 0)
    }
    
    func testStorageConfiguration() {
        XCTAssertEqual(AppConfiguration.Storage.maxHistoryItems, 1000)
        XCTAssertEqual(AppConfiguration.Storage.cacheExpirationDays, 30)
        XCTAssertEqual(AppConfiguration.Storage.maxCacheSizeMB, 50)
        
        XCTAssertGreaterThan(AppConfiguration.Storage.maxHistoryItems, 0)
        XCTAssertGreaterThan(AppConfiguration.Storage.cacheExpirationDays, 0)
        XCTAssertGreaterThan(AppConfiguration.Storage.maxCacheSizeMB, 0)
    }
    
    func testUIConfiguration() {
        XCTAssertEqual(AppConfiguration.UI.animationDuration, 0.3)
        XCTAssertEqual(AppConfiguration.UI.hapticFeedbackEnabled, true)
        XCTAssertEqual(AppConfiguration.UI.waveformUpdateInterval, 0.1)
        
        XCTAssertGreaterThan(AppConfiguration.UI.animationDuration, 0)
        XCTAssertGreaterThan(AppConfiguration.UI.waveformUpdateInterval, 0)
    }
    
    func testUIColors() {
        XCTAssertEqual(AppConfiguration.UI.Colors.primary, "#FF69B4")
        XCTAssertEqual(AppConfiguration.UI.Colors.secondary, "#FF1493")
        XCTAssertEqual(AppConfiguration.UI.Colors.accent, "#FFB6C1")
        XCTAssertEqual(AppConfiguration.UI.Colors.background, "#FFEEF8")
        XCTAssertEqual(AppConfiguration.UI.Colors.text, "#2C2C2E")
        XCTAssertEqual(AppConfiguration.UI.Colors.secondaryText, "#8E8E93")
        
        let colors = [
            AppConfiguration.UI.Colors.primary,
            AppConfiguration.UI.Colors.secondary,
            AppConfiguration.UI.Colors.accent,
            AppConfiguration.UI.Colors.background,
            AppConfiguration.UI.Colors.text,
            AppConfiguration.UI.Colors.secondaryText
        ]
        
        for color in colors {
            XCTAssertTrue(color.hasPrefix("#"))
            XCTAssertTrue(color.count == 7)
        }
    }
    
    func testUISpacing() {
        XCTAssertEqual(AppConfiguration.UI.Spacing.xs, 4)
        XCTAssertEqual(AppConfiguration.UI.Spacing.sm, 8)
        XCTAssertEqual(AppConfiguration.UI.Spacing.md, 16)
        XCTAssertEqual(AppConfiguration.UI.Spacing.lg, 24)
        XCTAssertEqual(AppConfiguration.UI.Spacing.xl, 32)
        
        XCTAssertLessThan(AppConfiguration.UI.Spacing.xs, AppConfiguration.UI.Spacing.sm)
        XCTAssertLessThan(AppConfiguration.UI.Spacing.sm, AppConfiguration.UI.Spacing.md)
        XCTAssertLessThan(AppConfiguration.UI.Spacing.md, AppConfiguration.UI.Spacing.lg)
        XCTAssertLessThan(AppConfiguration.UI.Spacing.lg, AppConfiguration.UI.Spacing.xl)
    }
    
    func testUIBorderRadius() {
        XCTAssertEqual(AppConfiguration.UI.BorderRadius.sm, 8)
        XCTAssertEqual(AppConfiguration.UI.BorderRadius.md, 12)
        XCTAssertEqual(AppConfiguration.UI.BorderRadius.lg, 16)
        XCTAssertEqual(AppConfiguration.UI.BorderRadius.xl, 24)
        
        XCTAssertLessThan(AppConfiguration.UI.BorderRadius.sm, AppConfiguration.UI.BorderRadius.md)
        XCTAssertLessThan(AppConfiguration.UI.BorderRadius.md, AppConfiguration.UI.BorderRadius.lg)
        XCTAssertLessThan(AppConfiguration.UI.BorderRadius.lg, AppConfiguration.UI.BorderRadius.xl)
    }
    
    func testPrivacyConfiguration() {
        XCTAssertFalse(AppConfiguration.Privacy.microphoneUsageDescription.isEmpty)
        XCTAssertFalse(AppConfiguration.Privacy.networkUsageDescription.isEmpty)
        
        XCTAssertTrue(AppConfiguration.Privacy.microphoneUsageDescription.contains("microphone"))
        XCTAssertTrue(AppConfiguration.Privacy.networkUsageDescription.contains("internet"))
    }
    
    func testFeaturesConfiguration() {
        XCTAssertEqual(AppConfiguration.Features.enrichmentEnabled, true)
        XCTAssertEqual(AppConfiguration.Features.historyEnabled, true)
        XCTAssertEqual(AppConfiguration.Features.sharingEnabled, true)
        XCTAssertEqual(AppConfiguration.Features.offlineModeEnabled, false)
        XCTAssertEqual(AppConfiguration.Features.analyticsEnabled, false)
    }
    
    func testDebugConfiguration() {
        XCTAssertEqual(AppConfiguration.Debug.loggingEnabled, true)
        XCTAssertEqual(AppConfiguration.Debug.mockDataEnabled, false)
        XCTAssertEqual(AppConfiguration.Debug.skipPermissions, false)
    }
    
    func testAppMetadata() {
        let appVersion = AppConfiguration.appVersion
        let buildNumber = AppConfiguration.buildNumber
        let bundleIdentifier = AppConfiguration.bundleIdentifier
        
        XCTAssertFalse(appVersion.isEmpty)
        XCTAssertFalse(buildNumber.isEmpty)
        XCTAssertFalse(bundleIdentifier.isEmpty)
        
        XCTAssertTrue(bundleIdentifier.contains("."))
    }
    
    func testDebugBuildFlag() {
        let isDebug = AppConfiguration.isDebugBuild
        
        #if DEBUG
        XCTAssertTrue(isDebug)
        #else
        XCTAssertFalse(isDebug)
        #endif
    }
    
    func testConfigurationConsistency() {
        XCTAssertLessThan(AppConfiguration.Shazam.minRecordingDuration, AppConfiguration.Shazam.maxRecordingDuration)
        XCTAssertLessThan(AppConfiguration.UI.waveformUpdateInterval, AppConfiguration.UI.animationDuration)
        XCTAssertGreaterThan(AppConfiguration.API.timeoutInterval, AppConfiguration.API.rateLimitDelay)
    }
}
