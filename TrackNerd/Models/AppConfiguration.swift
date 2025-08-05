import Foundation

struct AppConfiguration {
    
    struct API {
        static let baseURL = "https://api.tracknerd.com"
        static let enrichEndpoint = "/enrich"
        static let timeoutInterval: TimeInterval = 30.0
        static let maxRetryAttempts = 3
        static let rateLimitDelay: TimeInterval = 1.0
    }
    
    struct Shazam {
        static let maxRecordingDuration: TimeInterval = 15.0
        static let minRecordingDuration: TimeInterval = 3.0
        static let audioSessionCategory = "AVAudioSessionCategoryRecord"
        static let sampleRate: Double = 44100.0
    }
    
    struct Storage {
        static let maxHistoryItems = 1000
        static let cacheExpirationDays = 30
        static let maxCacheSizeMB = 50
    }
    
    struct UI {
        static let animationDuration: TimeInterval = 0.3
        static let hapticFeedbackEnabled = true
        static let waveformUpdateInterval: TimeInterval = 0.1
        
        struct Colors {
            static let primary = "#FF69B4"
            static let secondary = "#FF1493"
            static let accent = "#FFB6C1"
            static let background = "#FFEEF8"
            static let text = "#2C2C2E"
            static let secondaryText = "#8E8E93"
        }
        
        struct Spacing {
            static let xs: CGFloat = 4
            static let sm: CGFloat = 8
            static let md: CGFloat = 16
            static let lg: CGFloat = 24
            static let xl: CGFloat = 32
        }
        
        struct BorderRadius {
            static let sm: CGFloat = 8
            static let md: CGFloat = 12
            static let lg: CGFloat = 16
            static let xl: CGFloat = 24
        }
    }
    
    struct Privacy {
        static let microphoneUsageDescription = "TrackNerd needs microphone access to identify music playing around you."
        static let networkUsageDescription = "TrackNerd connects to the internet to provide rich information about your music discoveries."
    }
    
    struct Features {
        static let enrichmentEnabled = true
        static let historyEnabled = true
        static let sharingEnabled = true
        static let offlineModeEnabled = false
        static let analyticsEnabled = false
    }
    
    struct Debug {
        static let loggingEnabled = true
        static let mockDataEnabled = false
        static let skipPermissions = false
    }
}

extension AppConfiguration {
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.musicnerd.TrackNerd"
    }
}
